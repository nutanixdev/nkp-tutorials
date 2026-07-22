
# NDK Recipes

This directory contains a collection of recipes for NDK.


## Recipe Descriptions

### 01_secrets.yaml
Defines Kubernetes secrets required. Apply this manifest first to ensure all subsequent recipes have access to the necessary secrets.

### 02_upfo.yaml
Unplanned failover recipe to be applied on the DR cluster.

### 03_reset-replication.yaml
Use this when you need to clear existing replication state or re-establish replication after a failover.

### 04_upfo_primary_cleanup.yaml
Contains cleanup steps for the primary cluster after a failover. This ensures that resources are properly removed or marked to avoid conflicts when the application is running on the DR cluster. Apply on the DR cluster.

### 05_pfo.yaml
Planned failover - trigger failover operation in either direction.

---

Apply the recipes in the recommended order for a typical protection and failover workflow.
