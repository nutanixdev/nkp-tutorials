#!/bin/bash

# ==============================================================================
# Library: prism-apis.sh
# Purpose: Reusable Nutanix Prism Central v3 API functions.
# ==============================================================================

# Internal helper for API calls
_pc_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local insecure=""
    [ "$NUTANIX_INSECURE" = "true" ] && insecure="-k"

    curl $insecure -s -u "$NUTANIX_USER:$NUTANIX_PASSWORD" \
        -X "$method" "https://$NUTANIX_ENDPOINT:$NUTANIX_PORT/api/nutanix/v3/$endpoint" \
        -H "Content-Type: application/json" \
        -d "$data"
}

# List Images with a custom filter
pc_list_images() {
    local filter=$1
    local payload="{\"kind\": \"image\", \"filter\": \"$filter\"}"
    _pc_call "POST" "images/list" "$payload"
}

# Import an Image from URL
pc_import_image() {
    local name=$1
    local url=$2
    local payload="{
        \"spec\": {
            \"name\": \"$name\",
            \"resources\": {
                \"image_type\": \"DISK_IMAGE\",
                \"source_uri\": \"$url\"
            }
        },
        \"metadata\": { \"kind\": \"image\" }
    }"
    _pc_call "POST" "images" "$payload"
}

# Wait for a Task to complete
# Usage: pc_wait_for_task "task-uuid-here"
pc_wait_for_task() {
    local task_uuid=$1
    local status="RUNNING"
    local attempt=1
    local max_attempts=60 # 5 minutes with 5s sleep

    log_info "Monitoring task: $task_uuid"

    while [[ "$status" == "RUNNING" || "$status" == "PENDING" || "$status" == "QUEUED" ]]; do
        if [ $attempt -gt $max_attempts ]; then
            log_error "Timeout waiting for task $task_uuid"
            return 1
        fi

        # Get task status
        local task_resp=$(_pc_call "GET" "tasks/$task_uuid" "")
        status=$(echo "$task_resp" | jq -r '.status')
        local progress=$(echo "$task_resp" | jq -r '.percentage_complete // 0')

        if [[ "$status" == "SUCCEEDED" ]]; then
            log_success "Task completed successfully."
            return 0
        elif [[ "$status" == "FAILED" ]]; then
            local reason=$(echo "$task_resp" | jq -r '.error_detail')
            log_error "Task failed: $reason"
            return 1
        fi

        debug_log "Task $task_uuid: $status ($progress%)"
        echo -n "." # Visual progress indicator
        sleep 5
        ((attempt++))
    done
}