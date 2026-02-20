#!/bin/bash

# ==============================================================================
# Script: 02_check_prerequisites.sh
# Purpose: Align NKP CLI, Version Mapping, and Prism Central OS Images.
# Usage: ./scripts/02_check_prerequisites.sh (Run from project root)
# ==============================================================================

# 1. Path Resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)" 
LIB_FUNC="$REPO_ROOT/lib/common-functions.sh"
LIB_API="$REPO_ROOT/lib/prism-apis.sh"
MAP_FILE="$REPO_ROOT/metadata/version_map.json"
CONFIG_DIR="$SCRIPT_DIR/../configs"
USER_ENV="$CONFIG_DIR/nkp.env"

# Source Library Functions
source "$LIB_FUNC" || { echo "Error sourcing lib/common-functions.sh"; exit 1; }
source "$LIB_API" || { echo "Error sourcing lib/prism-apis.sh"; exit 1; }
load_env "$USER_ENV"

echo "-----------------------------------------------------"
log_info "[STEP 02] Prerequisites & Resource Alignment"
echo "-----------------------------------------------------"

# --- PART 1: SYSTEM TOOL CHECK ---

# Define the list of required binaries
REQUIRED_TOOLS="curl tar jq"

log_info "Verifying system dependencies..."

for tool in $REQUIRED_TOOLS; do
    if ! command -v "$tool" &> /dev/null; then
        log_error "Required tool '$tool' is not installed."
        exit 1
    fi
done

log_success "System tools verified: $REQUIRED_TOOLS"

# --- PART 2: NKP CLI CHECK & INSTALL ---
if ! command -v nkp &> /dev/null; then
    echo "-----------------------------------------------------"
    echo "To download the NKP CLI:"
    echo "1. Open your browser: https://portal.nutanix.com/page/downloads?product=nkp"
    echo "2. Find the 'NKP for Linux' section."
    echo "3. Copy the download link (usually a .tar.gz file)."
    echo "-----------------------------------------------------"
    read -p "Please paste the NKP CLI Download URL: " NKP_URL
    if [ -n "$NKP_URL" ]; then
        log_info "Downloading NKP CLI archive..."
        curl -L "$NKP_URL" -o /tmp/nkp.tar.gz
        log_info "Extracting binary..."
        tar -xzf /tmp/nkp.tar.gz -C /tmp/
        if [ -f "/tmp/nkp" ]; then
            log_info "Installing to /usr/local/bin (requires sudo)..."
            sudo mv /tmp/nkp /usr/local/bin/nkp
            sudo chmod +x /usr/local/bin/nkp
            log_success "NKP CLI installed successfully!"
            rm /tmp/nkp.tar.gz
        else
            log_error "'nkp' binary not found in the archive."
            exit 1
        fi
    else
        log_error "A URL is required to install the NKP CLI."; exit 1
    fi
fi

NKP_VERSION=$(nkp version -o json | jq -r '.nkp.gitVersion | ltrimstr("v")')
log_success "Detected NKP CLI Version: $NKP_VERSION"

# --- PART 3: VERSION COMPATIBILITY MAPPING ---
if [ ! -f "$MAP_FILE" ]; then
    log_error "Global metadata file missing at $MAP_FILE"; exit 1
fi

K8S_VERSION=$(jq -r --arg NKP_VER "$NKP_VERSION" '.mappings[] | select(.nkp == $NKP_VER) | .k8s' "$MAP_FILE")
[ -z "$K8S_VERSION" ] || [ "$K8S_VERSION" == "null" ] && { log_error "No mapping found for $NKP_VERSION"; exit 1; }
log_success "Targeting Kubernetes version: $K8S_VERSION"

# --- PART 4: IMAGE DISCOVERY & SELECTION ---
log_info "Searching Prism Central for compatible Rocky images..."
IMAGE_DATA=$(pc_list_images "name==nkp-rocky.*")
mapfile -t MATCHING_IMAGES < <(echo "$IMAGE_DATA" | jq -r --arg K8S "$K8S_VERSION" '.entities[] | .status.name | select(contains($K8S))')

if [ ${#MATCHING_IMAGES[@]} -eq 0 ]; then
    echo "-----------------------------------------------------"
    log_error "No Rocky image found for K8s $K8S_VERSION."
    echo "To download the required Rocky OS image:"
    echo "1. Open browser: https://portal.nutanix.com/page/downloads?product=nkp"
    echo "2. Switch to 'NKP Operating System Images' and look for the 'Rocky Linux' version."
    echo "3. Ensure it matches NKP: $NKP_VERSION and K8s: $K8S_VERSION."
    echo "4. Copy the download link (with the long signature strings)."
    echo "-----------------------------------------------------"
    read -p "Provide URL for Rocky $K8S_VERSION (.qcow2) image to import: " IMAGE_URL
    if [ -n "$IMAGE_URL" ]; then
        URL_WITHOUT_QUERY="${IMAGE_URL%%\?*}"
        IMPORT_NAME="${URL_WITHOUT_QUERY##*/}"
        IMPORT_RESPONSE=$(pc_import_image "$IMPORT_NAME" "$IMAGE_URL")
        TASK_UUID=$(echo "$IMPORT_RESPONSE" | jq -r '.status.execution_context.task_uuid // empty')
        if [ -n "$TASK_UUID" ] && [ "$TASK_UUID" != "null" ]; then
            log_info "Import started. Waiting for completion..."
            if pc_wait_for_task "$TASK_UUID"; then
                SELECTED_IMAGE="$IMPORT_NAME"
            else
                log_error "Image import failed during processing."; exit 1
            fi
        else
            log_error "Failed to initiate import: $IMPORT_RESPONSE"; exit 1
        fi
    else
        log_error "No URL provided."; exit 1
    fi
elif [ ${#MATCHING_IMAGES[@]} -eq 1 ]; then
    SELECTED_IMAGE="${MATCHING_IMAGES[0]}"
    log_success "Using image: $SELECTED_IMAGE"
else
    log_info "Multiple images found. Please select one:"
    for i in "${!MATCHING_IMAGES[@]}"; do
        printf "%d) %s\n" "$((i+1))" "${MATCHING_IMAGES[$i]}"
    done
    while true; do
        read -p "Choice [1-${#MATCHING_IMAGES[@]}]: " CHOICE
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#MATCHING_IMAGES[@]}" ]; then
            SELECTED_IMAGE="${MATCHING_IMAGES[$((CHOICE-1))]}"
            break
        else
            log_error "Invalid selection."
        fi
    done
fi

sed -i '/export NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME=/d' "$USER_ENV"
echo "export NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME=\"$SELECTED_IMAGE\"" >> "$USER_ENV"

# --- PART 5: AOS CLUSTER SELECTION ---
log_info "Discovering AOS Clusters..."
CLUSTER_DATA=$(pc_list_clusters)
mapfile -t CLUSTER_NAMES < <(echo "$CLUSTER_DATA" | jq -r '.entities[] | .status.name')

if [ ${#CLUSTER_NAMES[@]} -eq 1 ]; then
    SELECTED_CLUSTER="${CLUSTER_NAMES[0]}"
    log_success "Using Cluster: $SELECTED_CLUSTER"
else
    log_info "Select Target AOS Cluster (Prism Element):"
    for i in "${!CLUSTER_NAMES[@]}"; do
        printf "%d) %s\n" "$((i+1))" "${CLUSTER_NAMES[$i]}"
    done
    while true; do
        read -p "Choice [1-${#CLUSTER_NAMES[@]}]: " C_CHOICE
        if [[ "$C_CHOICE" =~ ^[0-9]+$ ]] && [ "$C_CHOICE" -ge 1 ] && [ "$C_CHOICE" -le "${#CLUSTER_NAMES[@]}" ]; then
            SELECTED_CLUSTER="${CLUSTER_NAMES[$((C_CHOICE-1))]}"
            break
        else
            log_error "Invalid selection."
        fi
    done
fi

sed -i '/export NUTANIX_PRISM_ELEMENT_CLUSTER_NAME=/d' "$USER_ENV"
echo "export NUTANIX_PRISM_ELEMENT_CLUSTER_NAME=\"$SELECTED_CLUSTER\"" >> "$USER_ENV"

# --- PART 6: SUBNET SELECTION ---
log_info "Fetching subnets for cluster: $SELECTED_CLUSTER"
SUBNET_DATA=$(pc_list_subnets)

mapfile -t SUBNET_RAW < <(echo "$SUBNET_DATA" | jq -r --arg CLUSTER "$SELECTED_CLUSTER" '
    .entities[] | 
    select(.status.cluster_reference.name == $CLUSTER or .status.resources.subnet_type == "OVERLAY") | 
    [
        .status.name,
        .status.resources.subnet_type,
        (.status.resources.vlan_id // "N/A"),
        "\((.status.resources.ip_config.subnet_ip // "0.0.0.0"))/\((.status.resources.ip_config.prefix_length // "0"))",
        (if .status.resources.ip_usage_stats.ip_pools_stats then
            [.status.resources.ip_usage_stats.ip_pools_stats[] | "\(.range) (Free: \(.num_free_ips))"] | join(";")
         else
            "NO IPAM"
         end)
    ] | join("|")
')

if [ ${#SUBNET_RAW[@]} -eq 0 ]; then
    log_error "No subnets found for cluster $SELECTED_CLUSTER."; exit 1
fi

echo ""
printf "%-4s %-25s %-10s %-6s %-18s %s\n" "ID" "NAME" "TYPE" "VLAN" "PREFIX" "IPAM POOLS (Range & Availability)"
echo "----------------------------------------------------------------------------------------------------------------------------------"

for i in "${!SUBNET_RAW[@]}"; do
    IFS='|' read -r name type vlan prefix pools <<< "${SUBNET_RAW[$i]}"
    IFS=';' read -r -a pool_array <<< "$pools"
    printf "%-4d %-25s %-10s %-6s %-18s %s\n" "$((i+1))" "$name" "$type" "$vlan" "$prefix" "${pool_array[0]}"
    for ((j=1; j<${#pool_array[@]}; j++)); do
        printf "%-4s %-25s %-10s %-6s %-18s %s\n" "" "" "" "" "" "${pool_array[$j]}"
    done
done

while true; do
    echo ""
    read -p "Select Subnet for NKP Nodes (Must be IPAM ENABLED) [1-${#SUBNET_RAW[@]}]: " S_CHOICE
    S_IDX=$((S_CHOICE-1))
    if [[ "$S_CHOICE" =~ ^[0-9]+$ ]] && [ "$S_IDX" -ge 0 ] && [ "$S_IDX" -lt "${#SUBNET_RAW[@]}" ]; then
        IFS='|' read -r s_name s_type s_vlan s_prefix s_pools <<< "${SUBNET_RAW[$S_IDX]}"
        if [[ "$s_pools" == "NO IPAM" ]]; then
            log_error "Subnet '$s_name' has no IPAM pools. NKP requires Nutanix IPAM."
        elif [[ ! "$s_pools" =~ \(Free:\ [1-9] ]]; then
            log_error "Subnet '$s_name' has 0 free IPs in the IPAM pool(s)."
        else
            SELECTED_SUBNET="$s_name"
            log_success "Selected Subnet: $SELECTED_SUBNET"
            break
        fi
    else
        log_error "Invalid selection."
    fi
done

sed -i '/export NUTANIX_SUBNET_NAME=/d' "$USER_ENV"
echo "export NUTANIX_SUBNET_NAME=\"$SELECTED_SUBNET\"" >> "$USER_ENV"

echo "-----------------------------------------------------"
log_success "Environment Alignment Complete."
log_info "NEXT STEP: Run ./scripts/03_install_nkp_cluster.sh"
echo "-----------------------------------------------------"