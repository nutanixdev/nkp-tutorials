
# k8gb Installation Guide

This guide provides step-by-step instructions for installing k8gb on two clusters: `k8s-primary` and `k8s-dr`. k8gb enables global server load balancing (GSLB) for Kubernetes applications across multiple clusters.

## Prerequisites

- Access to two Kubernetes clusters (`k8s-primary` and `k8s-dr`).
- `kubectl` configured to interact with both clusters.
- Helm installed.
- A Cloudflare API token for DNS management (Follow k8gb documentation for other DNS providers).

## Step 1: Create Namespace and Secret

Create the `k8gb` namespace and the Cloudflare API token secret in both clusters.

```bash
kubectl create namespace k8gb
kubectl -n k8gb create secret generic cloudflare --from-literal=token=YOUR_CLOUDFLARE_API_TOKEN
```

Replace `YOUR_CLOUDFLARE_API_TOKEN` with your actual Cloudflare API token.

## Step 2: Install k8gb Helm Chart

Add the k8gb Helm repository and install the chart on each cluster with the appropriate configurations.

### On k8s-primary cluster

```bash
helm repo add k8gb https://www.k8gb.io
helm install k8gb k8gb/k8gb \
  --namespace k8gb --create-namespace \
  --set k8gb.clusterGeoTag="k8s-primary" \
  --set k8gb.extGslbClustersGeoTags="k8s-dr" \
  --set k8gb.nsRecordTTL=60 \
  --set 'k8gb.dnsZones[0].loadBalancedZone=gslb.thencpnutanix.com' \
  --set 'k8gb.dnsZones[0].parentZone=thencpnutanix.com' \
  --set extdns.enabled=true \
  --set extdns.fullnameOverride="k8gb-external-dns" \
  --set 'extdns.provider.name=cloudflare' \
  --set 'extdns.domainFilters[0]=thencpnutanix.com' \
  --set 'extdns.txtPrefix=k8gb-k8s-primary-' \
  --set 'extdns.txtOwnerId=k8gb-gslb.thencpnutanix.com-k8s-primary' \
  --set 'extdns.env[0].name=CF_API_TOKEN' \
  --set 'extdns.env[0].valueFrom.secretKeyRef.name=cloudflare' \
  --set 'extdns.env[0].valueFrom.secretKeyRef.key=token' \
  --set coredns.enabled=true \
  --set coredns.serviceType=LoadBalancer
```

### On k8s-dr cluster

```bash
helm repo add k8gb https://www.k8gb.io
helm install k8gb k8gb/k8gb \
  --namespace k8gb --create-namespace \
  --set k8gb.clusterGeoTag="k8s-dr" \
  --set k8gb.extGslbClustersGeoTags="k8s-primary" \
  --set k8gb.nsRecordTTL=60 \
  --set 'k8gb.dnsZones[0].loadBalancedZone=gslb.thencpnutanix.com' \
  --set 'k8gb.dnsZones[0].parentZone=thencpnutanix.com' \
  --set extdns.enabled=true \
  --set extdns.fullnameOverride="k8gb-external-dns" \
  --set 'extdns.provider.name=cloudflare' \
  --set 'extdns.domainFilters[0]=thencpnutanix.com' \
  --set 'extdns.txtPrefix=k8gb-k8s-dr-' \
  --set 'extdns.txtOwnerId=k8gb-gslb.thencpnutanix.com-k8s-dr' \
  --set 'extdns.env[0].name=CF_API_TOKEN' \
  --set 'extdns.env[0].valueFrom.secretKeyRef.name=cloudflare' \
  --set 'extdns.env[0].valueFrom.secretKeyRef.key=token' \
  --set coredns.enabled=true \
  --set coredns.serviceType=LoadBalancer
```

## Step 3: Verify Installation

Check that the pods, services, and DNS endpoints are running correctly in the `k8gb` namespace.

```bash
kubectl get pods,svc,dnsendpoint -n k8gb
```

## Configuration Parameters

- `clusterGeoTag`: Unique identifier for the cluster (e.g., "k8s-primary" or "k8s-dr").
- `extGslbClustersGeoTags`: Comma-separated list of geo tags for external GSLB clusters to monitor for heartbeat.
- `nsRecordTTL`: TTL for NS records set by Cloudflare (60 seconds for free tier). This determines the minimum time for traffic routing to a failed site.
- `k8gb.dnsZones[0].parentZone`: Parent domain hosted in Cloudflare (e.g., "thencpnutanix.com").
- `k8gb.dnsZones[0].loadBalancedZone`: Subdomain used by the application (e.g., "gslb.thencpnutanix.com").
- `extdns`: Configuration for External-DNS, which k8gb uses to manage DNS entries. Refer to [External-DNS documentation](https://github.com/kubernetes-sigs/external-dns) and [k8gb examples](https://k8gb.io/) for more details.
- `coredns.enabled`: Deploys CoreDNS in the k8gb namespace.
- `coredns.serviceType`: Service type for CoreDNS (set to LoadBalancer).

## DNS Endpoint Configuration

The installation creates an ExternalDNS CR `DNSEndpoint` with the following specifications:

### For k8s-primary
```yaml
spec:
  endpoints:
    - dnsName: gslb.thencpnutanix.com
      recordTTL: 60
      recordType: NS
      targets:
        - gslb-ns-k8s-dr-gslb.thencpnutanix.com
        - gslb-ns-k8s-primary-gslb.thencpnutanix.com
    - dnsName: gslb-ns-k8s-primary-gslb.thencpnutanix.com
      recordTTL: 60
      recordType: A
      targets:
        - <loadbalancer_IP_address>
```

### For k8s-dr
```yaml
spec:
  endpoints:
    - dnsName: gslb.thencpnutanix.com
      recordTTL: 60
      recordType: NS
      targets:
        - gslb-ns-k8s-dr-gslb.thencpnutanix.com
        - gslb-ns-k8s-primary-gslb.thencpnutanix.com
   - dnsName: gslb-ns-k8s-dr-gslb.thencpnutanix.com
     recordTTL: 60
     recordType: A
     targets:
       - <loadbalancer_IP_address>
```


In Cloudflare, it creates two NS records for zone delegation for each target and an A record for the LB IP address used by coreDNS. There are also TXT records created by externalDNS - these are heartbeat records, ie each ExternalDNS can see this and know who’s the owner and will not delete it.