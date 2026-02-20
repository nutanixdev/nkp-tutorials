#!/bin/bash

# ==============================================================================
# Library: prism-apis.sh
# Purpose: Reusable Nutanix Prism Central v3 API functions.
# ==============================================================================

# --- INTERNAL HELPER ---

# Centralized function for all REST API calls
_pc_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local insecure=""
    
    [ "$NUTANIX_INSECURE" = "true" ] && insecure="-k"
    local url="https://$NUTANIX_ENDPOINT:$NUTANIX_PORT/api/nutanix/v3/$endpoint"

    debug_log "API Request: [$method] $url"
    [ -n "$data" ] && debug_log "Request Body: $data"

    local response
    response=$(curl $insecure -s -u "$NUTANIX_USER:$NUTANIX_PASSWORD" \
        -X "$method" "$url" \
        -H "Content-Type: application/json" \
        -d "$data")

    # Error check: if response is empty, the connection likely failed
    if [ -z "$response" ]; then
        log_error "No response from Prism Central at $url"
        return 1
    fi

    debug_log "API Response Received."
    debug_log "Full Content: $response"
    
    echo "$response"
}

# --- CLUSTER FUNCTIONS ---

# List AOS Clusters (Filters out Prism Central instances)
pc_list_clusters() {
    local raw_data
    raw_data=$(_pc_call "POST" "clusters/list" '{"kind": "cluster"}')
    
    # Selection: entities where .status.resources.config.service_list does NOT contain "PRISM_CENTRAL"
    echo "$raw_data" | jq -c '
        .entities |= map(
            select(
                (.status.resources.config.service_list // []) | 
                contains(["PRISM_CENTRAL"]) | not
            )
        )'
}

# --- IMAGE FUNCTIONS ---

# List Images with a specific filter
pc_list_images() {
    local filter="$1"
    local payload
    payload=$(jq -n --arg f "$filter" '{kind: "image", filter: $f}')
    
    _pc_call "POST" "images/list" "$payload"
}

# Import Image from URL
pc_import_image() {
    local name="$1"
    local url="$2"
    local payload
    
    # Build JSON safely with jq to handle special characters in URLs/Names
    payload=$(jq -n \
        --arg n "$name" \
        --arg u "$url" \
        '{
            spec: {
                name: $n,
                resources: {
                    image_type: "DISK_IMAGE",
                    source_uri: $u
                }
            },
            metadata: { kind: "image" }
        }')
        
    _pc_call "POST" "images" "$payload"
}

# --- SUBNET FUNCTIONS ---

# List all subnets
pc_list_subnets() {
    _pc_call "POST" "subnets/list" '{"kind": "subnet"}'
}

# --- TASK FUNCTIONS ---

# Poll a Task until completion (SUCCEEDED) or failure (FAILED)
pc_wait_for_task() {
    local task_uuid="$1"
    local status="RUNNING"
    local attempt=1
    local max_attempts=120 # 10 minutes total (120 * 5s)

    while [[ "$status" == "RUNNING" || "$status" == "PENDING" || "$status" == "QUEUED" ]]; do
        if [ "$attempt" -gt "$max_attempts" ]; then
            log_error "Timeout: Task $task_uuid exceeded $max_attempts attempts."
            return 1
        fi

        local task_resp
        task_resp=$(_pc_call "GET" "tasks/$task_uuid" "")
        status=$(echo "$task_resp" | jq -r '.status // "FAILED"')

        case "$status" in
            "SUCCEEDED")
                echo "" >&2 # Clear the progress line
                log_success "Task $task_uuid completed successfully."
                return 0
                ;;
            "FAILED")
                echo "" >&2
                local err
                err=$(echo "$task_resp" | jq -r '.error_detail // "Unknown API Error"')
                log_error "Task $task_uuid failed: $err"
                return 1
                ;;
            *)
                # Print progress dots to stderr to keep stdout clean for data capture
                echo -n "." >&2
                sleep 5
                ((attempt++))
                ;;
        esac
    done
}