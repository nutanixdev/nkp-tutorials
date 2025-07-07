#!/bin/bash

set -e

# Define colors
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# CONFIGURATION
MANIFEST_URL="https://raw.githubusercontent.com/nutanixdev/nkp-tutorials/refs/heads/main/ai-cpu-on-nkp-with-localai/aio.yaml"
DEPLOYMENT_NAME="localai"
NAMESPACE="localai"
INGRESS_SERVICE="kommander-traefik"

# 1. Apply manifest
echo -e "\n${BLUE}🚀 Step 1: Applying Kubernetes manifest...${RESET}"
echo -e "${YELLOW}Fetching from:${RESET} $MANIFEST_URL\n"
kubectl apply -f "$MANIFEST_URL"

# 2. Wait for deployment
echo -e "\n${BLUE}⏳ Step 2: Waiting for deployment to be ready...${RESET}"
kubectl rollout status deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"

# 3. Get ingress IP
echo -e "\n${BLUE}🌐 Step 3: Retrieving Ingress IP...${RESET}"
INGRESS_IP=$(kubectl get svc "$INGRESS_SERVICE" -n kommander -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$INGRESS_IP" ]; then
  echo -e "\n${RED}❌ Error:${RESET} Could not retrieve ingress IP. Is the service type LoadBalancer and properly exposed?"
  exit 1
fi

# 4. Output access URL
FINAL_URL="http://$INGRESS_IP/localai"

echo -e "\n${GREEN}✅ Done!${RESET}"
echo -e "${GREEN}🌍 Access your service here:${RESET} ${YELLOW}$FINAL_URL${RESET}\n"
