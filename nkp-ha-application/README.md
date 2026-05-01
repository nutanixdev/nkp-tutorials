
# NKP Application HA & DR Solution

This repository contains declarative configurations for deploying a highly available, active/passive application solution across two independent Nutanix Kubernetes Platform (NKP) clusters.

The solution leverages **GitOps** for configuration consistency and **Nutanix Data Services for Kubernetes (NDK)** for stateful data protection across two datacenters, providing business continuity and disaster recovery (BCDR) for cloud-native applications.

---

## Key Design Patterns

### 1. GitOps Structure

- **Principle:** Uses a Git repository as the single source of truth for all infrastructure and application configurations.
- **Tool:** FluxCD maintains and synchronizes application and networking manifests (e.g., Gateway API and GSLB) across both NKP clusters.

### 2. App of Apps Pattern

- **Description:** An advanced GitOps model for managing hierarchical and sequential deployments using nested Kustomization resources.
- **Mechanism:** A root Kustomization resource references nested resources to orchestrate complex setups.
- **Use Case:** Ensures foundational components (like networking and GSLB) are deployed before core application workloads on both clusters.

### 3. Modular Design

- **Application-level changes:** Apply changes in the `applications/` directory to reflect them across all clusters.
- **Cluster-level overrides:** Apply per-cluster overrides with patches in the `clusters/` directory.
- **Adding new applications:** Add manifests to `applications/` and reference them with a Kustomization in the relevant cluster directory.

---

## Solution Components (Directories)


The configuration manifests for the core BCDR tools are organized as follows:

1. [**k8gb**](k8gb/):  
   Configurations for the cloud-native Kubernetes global load balancer, used for granular, application-level failover by dynamically updating DNS records.

2. [**ndk**](ndk/):  
   Configurations for Nutanix Data Services for Kubernetes (NDK), the core technology for stateful application resilience, including application protection definitions and data replication policies.

3. [**velero**](velero-backup/):  
   Manifests for using Velero for namespace or cluster-level backups, offering a faster restoration path for localized failures within the original cluster.

---