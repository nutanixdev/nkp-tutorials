#!/bin/bash

# ==============================================================================
# Script: 01_init_nkp_env.sh
# Purpose: basic configuration and credential gathering for NKP & GitLab.
# Usage: ./scripts/01_init_nkp_env.sh
# ==============================================================================

# 1. Determine Project Root (the directory above 'scripts')
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/configs"
ENV_FILE="$CONFIG_DIR/nkp.env"

# Ensure the configs directory exists
mkdir -p "$CONFIG_DIR"

echo "-----------------------------------------------------"
echo "  [STEP 01] Nutanix NKP Environment Initializer"
echo "  Target: $ENV_FILE"
echo "-----------------------------------------------------"

# 2. Gather Inputs
# Mandatory Nutanix Credentials
read -p "Enter NUTANIX_USER: " NUTANIX_USER
read -s -p "Enter NUTANIX_PASSWORD: " NUTANIX_PASSWORD
echo "" # New line after hidden password input

# Connection details with Default Values
read -p "Enter NUTANIX_ENDPOINT [10.0.0.1]: " INPUT_ENDPOINT
NUTANIX_ENDPOINT=${INPUT_ENDPOINT:-10.0.0.1}

read -p "Enter NUTANIX_PORT [9440]: " INPUT_PORT
NUTANIX_PORT=${INPUT_PORT:-9440}

# Settings with Defaults
read -p "Allow Insecure SSL (true/false) [true]: " INPUT_INSECURE
NUTANIX_INSECURE=${INPUT_INSECURE:-true}

read -p "Request Timeout in seconds [60]: " INPUT_TIMEOUT
NUTANIX_TIMEOUT=${INPUT_TIMEOUT:-60}

# 3. Generate the Credentials File
# We use 'export' inside the file so it can be 'sourced' easily by other scripts.
cat <<EOF > "$ENV_FILE"
# Nutanix NKP Credentials - Auto-generated
# Generated on: $(date)

export NUTANIX_USER="$NUTANIX_USER"
export NUTANIX_PASSWORD="$NUTANIX_PASSWORD"
export NUTANIX_ENDPOINT="$NUTANIX_ENDPOINT"
export NUTANIX_PORT="$NUTANIX_PORT"
export NUTANIX_INSECURE="$NUTANIX_INSECURE"
export NUTANIX_TIMEOUT="$NUTANIX_TIMEOUT"
export PROJECT_ROOT="$PROJECT_ROOT"
EOF

# 4. Set Permissions (Read/Write for owner only)
chmod 600 "$ENV_FILE"

echo "-----------------------------------------------------"
echo "SUCCESS: Configuration saved to configs/nkp.env"
echo "Security: File permissions restricted (chmod 600)."
echo ""
echo "NEXT STEP: Run ./scripts/02_validate_cluster.sh"
echo "-----------------------------------------------------"