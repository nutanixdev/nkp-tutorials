#!/bin/bash

# ==============================================================================
# Script: 01_init_nkp_env.sh
# Purpose: Initialize or update environment credentials for NKP tutorial.
# Usage: ./scripts/01_init_nkp_env.sh (Run from project root)
# ==============================================================================

# 1. Path Resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_FILE="$REPO_ROOT/lib/common-functions.sh"
CONFIG_DIR="$SCRIPT_DIR/../configs"
USER_ENV="$CONFIG_DIR/nkp.env"

# Source Common Functions
if [ -f "$LIB_FILE" ]; then
    source "$LIB_FILE"
else
    echo "ERROR: Could not find lib/common-functions.sh at $LIB_FILE"
    exit 1
fi

mkdir -p "$CONFIG_DIR"

echo "-----------------------------------------------------"
log_info "[STEP 01] Nutanix NKP Environment Initializer"
echo "-----------------------------------------------------"

# 2. Check for existing config
RECREATE="true"
if [ -f "$USER_ENV" ]; then
    log_info "An existing configuration was found at $USER_ENV"
    read -p "Do you want to use the existing configuration? (y/n) [y]: " USE_EXISTING
    USE_EXISTING=${USE_EXISTING:-y}

    if [[ "$USE_EXISTING" =~ ^[Yy]$ ]]; then
        RECREATE="false"
        log_success "Using existing configuration."
    else
        # Load existing values into memory to use as defaults
        source "$USER_ENV"
        log_info "Updating configuration. Current values will be shown as defaults."
    fi
fi

# 3. Prompting Phase (Only if RECREATE is true)
if [ "$RECREATE" = "true" ]; then
    # Helper to prompt with existing variable as default
    # Usage: prompt_default "Prompt Name" "CurrentVarValue" "GlobalDefaultIfNoVar"
    
    read -p "Enter NUTANIX_USER [${NUTANIX_USER}]: " NEW_USER
    NUTANIX_USER=${NEW_USER:-$NUTANIX_USER}

    read -s -p "Enter NUTANIX_PASSWORD (hidden): " NEW_PASS
    # If they just press enter, keep the old password
    NUTANIX_PASSWORD=${NEW_PASS:-$NUTANIX_PASSWORD}
    echo ""

    read -p "Enter NUTANIX_ENDPOINT [${NUTANIX_ENDPOINT:-10.0.0.1}]: " NEW_ENDPOINT
    NUTANIX_ENDPOINT=${NEW_ENDPOINT:-${NUTANIX_ENDPOINT:-10.0.0.1}}

    read -p "Enter NUTANIX_PORT [${NUTANIX_PORT:-9440}]: " NEW_PORT
    NUTANIX_PORT=${NEW_PORT:-${NUTANIX_PORT:-9440}}

    read -p "Allow Insecure SSL [${NUTANIX_INSECURE:-true}]: " NEW_INSECURE
    NUTANIX_INSECURE=${NEW_INSECURE:-${NUTANIX_INSECURE:-true}}

    read -p "Enable Debug Mode [${NUTANIX_DEBUG:-false}]: " NEW_DEBUG
    NUTANIX_DEBUG=${NEW_DEBUG:-${NUTANIX_DEBUG:-false}}

    # 4. Generate the Credentials File
    cat <<EOF > "$USER_ENV"
# Nutanix NKP Credentials - Updated $(date)
export NUTANIX_USER="$NUTANIX_USER"
export NUTANIX_PASSWORD="$NUTANIX_PASSWORD"
export NUTANIX_ENDPOINT="$NUTANIX_ENDPOINT"
export NUTANIX_PORT="$NUTANIX_PORT"
export NUTANIX_INSECURE="$NUTANIX_INSECURE"
export NUTANIX_DEBUG="$NUTANIX_DEBUG"
EOF

    chmod 600 "$USER_ENV"
    log_info "Security: File permissions restricted (chmod 600)."
    log_success "Configuration saved to $USER_ENV."
fi

echo "-----------------------------------------------------"
log_info "NEXT STEP: Run ./scripts/02_check_prerequisites.sh"
echo "-----------------------------------------------------"