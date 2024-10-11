#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#------------------------------------------------------------------------------

# Copyright 2024 Nutanix, Inc
#
# Licensed under the MIT License;
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#------------------------------------------------------------------------------

# Maintainer:   Jose Gomez (jose.gomez@nutanix.com)
# Contributors: 

#------------------------------------------------------------------------------

# Create NKP Kubernetes cluster
# shellcheck source=/dev/null
source ~/variables.sh

echo "Creating NKP cluster ${CLUSTER_NAME}. This can take about 45 minutes depending on Internet connectivity"

nkp create cluster nutanix -c $CLUSTER_NAME \
    --kind-cluster-image $REGISTRY_MIRROR_URL/docker.io/mesosphere/konvoy-bootstrap:v$NKP_VERSION \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --kubernetes-service-load-balancer-ip-range $LB_IP_RANGE \
    --control-plane-endpoint-ip $CONTROL_PLANE_ENDPOINT_IP \
    --control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --control-plane-subnets $NUTANIX_SUBNET_NAME \
    --control-plane-replicas 1 \
    --worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --worker-subnets $NUTANIX_SUBNET_NAME \
    --worker-replicas 3 \
    --csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
    --registry-mirror-url http://$REGISTRY_MIRROR_URL/docker.io \
    --self-managed

# Make new cluster KUBECONFIG default
mkdir -p ~/.kube
cp "${CLUSTER_NAME}.conf" ~/.kube/config
chmod 600 ~/.kube/config
