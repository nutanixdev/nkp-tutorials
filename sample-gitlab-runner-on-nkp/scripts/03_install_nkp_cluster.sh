#!/bin/bash

# ==============================================================================
# Script: 03_install_nkp_cluster.sh
# Purpose: Provision a self-managed Nutanix NKP Cluster.
# Usage: ./scripts/03_install_nkp_cluster.sh (Run from project root)
# ==============================================================================

# 1. Path Resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)" 
LIB_FUNC="$REPO_ROOT/lib/common-functions.sh"
CONFIG_DIR="$SCRIPT_DIR/../configs"
DEFAULT_ENV="$CONFIG_DIR/nkp-defaults.env"
USER_ENV="$CONFIG_DIR/nkp.env"

# Source Library Functions
source "$LIB_FUNC" || { echo "Error sourcing lib/common-functions.sh"; exit 1; }

# --- PART 1: LOAD CONFIGURATIONS ---
# Load Defaults (committed to Git)
if [ -f "$DEFAULT_ENV" ]; then
    source "$DEFAULT_ENV"
    log_info "Loaded deployment defaults from $DEFAULT_ENV"
else
    log_error "Defaults file missing at $DEFAULT_ENV"
    exit 1
fi

# Load User Env (Ignored by Git, contains secrets)
load_env "$USER_ENV"

echo "-----------------------------------------------------"
log_info "[STEP 03] NKP Cluster Installation"
echo "-----------------------------------------------------"

# --- PART 2: GAP ANALYSIS & INTERACTIVE CAPTURE ---
# Define variables required for the 'nkp create cluster' command
CRITICAL_VARS=(
    "CLUSTER_NAME" 
    "NUTANIX_ENDPOINT" 
    "CONTROL_PLANE_ENDPOINT_IP" 
    "LB_IP_RANGE"
    "NUTANIX_PRISM_ELEMENT_CLUSTER_NAME"
    "NUTANIX_SUBNET_NAME"
    "NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME"
    "NUTANIX_STORAGE_CONTAINER_NAME"
)

MISSING_FOUND=false
for var in "${CRITICAL_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        log_info "Missing required variable: $var"
        read -p "Please enter value for $var: " USER_INPUT
        
        if [ -n "$USER_INPUT" ]; then
            # Export to current session
            export "$var"="$USER_INPUT"
            
            # Persist to nkp.env for future runs
            echo "export $var=\"$USER_INPUT\"" >> "$USER_ENV"
            log_success "Saved $var to $USER_ENV"
            MISSING_FOUND=true
        else
            log_error "$var is mandatory to continue."; exit 1
        fi
    fi
done

[ "$MISSING_FOUND" = true ] && log_success "All missing variables captured and persisted."

# --- PART 3: VERSIONING ---
# NKP_VERSION=$(nkp version -o=json | jq -r '.nkp.gitVersion')
# log_info "Executing deployment with NKP version: $NKP_VERSION"

# --- PART 4: CLUSTER CREATION ---
log_info "Initiating Nutanix cluster creation for: $CLUSTER_NAME"

nkp create cluster nutanix -c "$CLUSTER_NAME" \
    --endpoint "https://$NUTANIX_ENDPOINT:$NUTANIX_PORT" \
    --insecure \
    --kubernetes-service-load-balancer-ip-range "$LB_IP_RANGE" \
    --control-plane-endpoint-ip "$CONTROL_PLANE_ENDPOINT_IP" \
    --control-plane-prism-element-cluster "$NUTANIX_PRISM_ELEMENT_CLUSTER_NAME" \
    --control-plane-subnets "$NUTANIX_SUBNET_NAME" \
    --control-plane-replicas "$CONTROL_PLANE_REPLICAS" \
    --worker-prism-element-cluster "$NUTANIX_PRISM_ELEMENT_CLUSTER_NAME" \
    --worker-subnets "$NUTANIX_SUBNET_NAME" \
    --worker-replicas "$WORKER_NODES_REPLICAS" \
    --csi-storage-container "$NUTANIX_STORAGE_CONTAINER_NAME" \
    --vm-image "$NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME" \
    ${REGISTRY_URL:+--registry-url https://"$REGISTRY_URL"} \
    ${REGISTRY_USERNAME:+--registry-username "$REGISTRY_USERNAME"} \
    ${REGISTRY_PASSWORD:+--registry-password "$REGISTRY_PASSWORD"} \
    ${REGISTRY_MIRROR_URL:+--registry-mirror-url https://"$REGISTRY_MIRROR_URL"} \
    ${REGISTRY_MIRROR_URL:+--skip-preflight-checks=Registry} \
    --self-managed

# --- PART 5: POST-INSTALLATION ---
if [ $? -eq 0 ]; then
    log_success "$CLUSTER_NAME completed successfully!"
else
    log_error "NKP Cluster creation failed."
    exit 1
fi