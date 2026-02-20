#!/bin/bash

# ==============================================================================
# Library: common-functions.sh
# Purpose: Shared helper functions for all tutorial scripts.
# ==============================================================================

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Debug Logger
debug_log() {
    if [ "${NUTANIX_DEBUG}" = "true" ]; then
        # This sends the message to the terminal but NOT into variables
        echo -e "${YELLOW}[DEBUG]${NC} $1" >&2
    fi
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

log_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

load_env() {
    local env_file=$1
    if [ -f "$env_file" ]; then
        source "$env_file"
        debug_log "Environment loaded from $env_file"
    else
        log_error "Config file not found at $env_file. Please run Step 01."
        exit 1
    fi
}