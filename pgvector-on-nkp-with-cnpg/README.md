# 🧠 Running PostgreSQL + pgvector on NKP with CloudNativePG

This tutorial demonstrates how to deploy PostgreSQL with the `pgvector` extension on a Nutanix Kubernetes Platform (NKP) cluster using CloudNativePG (CNPG).

The deployment creates a PostgreSQL database named `app`, enables the `pgvector` extension, creates a sample `documents` table, inserts fake vector embeddings, and adds a HNSW index for similarity search testing.

This setup is designed for experimentation, demos, and RAG/vector-search proof-of-concepts running directly on Kubernetes.

> ✅ **Prerequisites**
>
> * A running NKP Kubernetes cluster
> * CloudNativePG Operator installed
> * `kubectl` access to the cluster
>
> ⚠️ **NKP Edition Guidance**
>
> * **NKP Ultimate**: Recommended. Use NKP Projects Continuous Deployment to deploy from Git.
> * **NKP Pro**: Supported. Apply the manifest manually with `kubectl`.

---

# Table of Contents

- [🧠 Running PostgreSQL + pgvector on NKP with CloudNativePG](#-running-postgresql--pgvector-on-nkp-with-cloudnativepg)
- [Table of Contents](#table-of-contents)
- [Deployment Options](#deployment-options)
- [Option 1: NKP Ultimate with Continuous Deployment](#option-1-nkp-ultimate-with-continuous-deployment)
  - [How NKP Determines What Gets Deployed](#how-nkp-determines-what-gets-deployed)
  - [HelmRelease-based Deployment](#helmrelease-based-deployment)
  - [Updating Helm Values](#updating-helm-values)
- [Option 2: Manual kubectl Deployment](#option-2-manual-kubectl-deployment)
- [What's Deployed](#whats-deployed)
- [Accessing the Database](#accessing-the-database)
- [Optional pgAdmin Deployment](#optional-pgadmin-deployment)
  - [Install the CNPG kubectl Plugin](#install-the-cnpg-kubectl-plugin)
    - [macOS](#macos)
    - [Linux / Generic Installation](#linux--generic-installation)
  - [Deploy pgAdmin](#deploy-pgadmin)
- [Cleanup](#cleanup)
- [File Overview](#file-overview)
  - [🧩 Related Links](#-related-links)

---

# Deployment Options

This demo supports two deployment models:

| Option                             | Recommended For          | Description                                                  |
| ---------------------------------- | ------------------------ | ------------------------------------------------------------ |
| NKP Ultimate Continuous Deployment | NKP Ultimate users       | NKP continuously reconciles the repository path using GitOps |
| Manual kubectl Deployment          | NKP Pro or quick testing | Apply the CNPG manifest directly with `kubectl`              |

---

# Option 1: NKP Ultimate with Continuous Deployment

With NKP Ultimate, the deployment can be fully managed through **NKP Projects Continuous Deployment** using Git as the source of truth.

Instead of manually applying manifests with `kubectl`, configure a Git source that points to this repository path.

Navigate to:

```text
Projects → Continuous Deployment → GitOps Sources
```

Create a new Git source with the following configuration:

| Field              | Value                                             |
| ------------------ | ------------------------------------------------- |
| Name               | `pgvector-on-nkp-with-cnpg`                       |
| Repository URL     | `https://github.com/nutanixdev/nkp-tutorials.git` |
| Git Ref Type       | `Branch`                                          |
| Branch Name        | `main`                       |
| Path               | `./pgvector-on-nkp-with-cnpg`                     |
| Primary Git Secret | `None`, unless your repository is private         |

Once the Git source is configured, NKP Continuous Deployment will reconcile the resources found in the selected path.

---

## How NKP Determines What Gets Deployed

This repository includes a `kustomization.yaml` file:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - helmrelease.yaml
# - pgvector-demo.yaml
```

The `kustomization.yaml` file determines what NKP deploys from the repository path.

In this example:

* `helmrelease.yaml` is enabled
* `pgvector-demo.yaml` is commented out
* NKP will therefore deploy the HelmRelease-based workflow
* `pgvector-demo.yaml` will be ignored

This means:

* NKP will render and apply the `HelmRelease`
* Flux will deploy the local Helm chart
* The deployment will appear in the NKP UI as a HelmRelease-managed application

If the repository instead contained:

```yaml
resources:
  - pgvector-demo.yaml
```

without a HelmRelease, NKP would simply deploy the raw Kubernetes manifests directly.

---

## HelmRelease-based Deployment

This repository includes:

```text
helmrelease.yaml
```

which deploys the local Helm chart:

```text
charts/pgvector-demo
```

The Helm chart renders a CloudNativePG PostgreSQL cluster with:

* PostgreSQL 17
* `pgvector`
* Sample vector data
* HNSW similarity index

The included HelmRelease looks similar to:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: pgvector-demo
spec:
  interval: 5m
  chart:
    spec:
      chart: ./pgvector-on-nkp-with-cnpg/charts/pgvector-demo
      sourceRef:
        kind: GitRepository
        name: pgvector-on-nkp-with-cnpg
      interval: 5m
```

---

## Updating Helm Values

The chart values are located in:

```text
charts/pgvector-demo/values.yaml
```

Example:

```yaml
name: pgvector-demo
instances: 1
imageName: ghcr.io/cloudnative-pg/postgresql:17-standard-trixie
storageSize: 10Gi
database: app
owner: app
```

This allows customization of:

* PostgreSQL image
* Storage size
* Cluster name
* Database name
* Replica count

without modifying the chart template directly.

---

# Option 2: Manual kubectl Deployment

For NKP Pro, or for quick testing, apply the manifest directly:

```bash
kubectl apply -f pgvector-demo.yaml
```

Wait for the PostgreSQL cluster to become ready:

```bash
kubectl get clusters.postgresql.cnpg.io
kubectl get pods
```

Unlike the NKP Ultimate GitOps workflow, this option applies the raw CloudNativePG manifest directly.

---

# What's Deployed

The demo deploys:

* A CloudNativePG PostgreSQL cluster
* PostgreSQL 17 using the CNPG standard image
* A database named `app`
* A database owner named `app`
* The `pgvector` PostgreSQL extension
* A sample `documents` table
* Fake vector embeddings
* A HNSW vector index for similarity search

---

# Accessing the Database

Connect to PostgreSQL:

```bash
kubectl exec -it pgvector-demo-1 -- psql -d app
```

Verify the installed extensions:

```sql
\dx
```

Verify the table exists:

```sql
\dt
```

Show all sample documents:

```sql
SELECT * FROM documents;
```

Run a vector similarity search:

```sql
SELECT
  title,
  content,
  embedding <=> '[0.10,0.20,0.30]'::vector AS distance
FROM documents
ORDER BY distance
LIMIT 3;
```

The smaller the distance value, the more similar the vector is to the query vector.

---

# Optional pgAdmin Deployment

For a friendly UI experience, you can deploy pgAdmin using the CloudNativePG `kubectl cnpg` plugin.

> ⚠️ **Important**
>
> The `kubectl cnpg` plugin is not installed by default.
>
> Install it first before using the pgAdmin helper commands.

---

## Install the CNPG kubectl Plugin

### macOS

```bash
brew install cloudnative-pg/tap/cnpg
```

### Linux / Generic Installation

```bash
curl -sSfL \
  https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh \
  | sudo sh -s -- -b /usr/local/bin
```

Verify installation:

```bash
kubectl cnpg version
```

---

## Deploy pgAdmin

Deploy pgAdmin in desktop mode:

```bash
kubectl cnpg pgadmin4 --mode desktop pgvector-demo
```

Port-forward locally:

```bash
kubectl port-forward \
  deployment/pgvector-demo-pgadmin4 \
  8080:80
```

Access pgAdmin:

```text
http://localhost:8080
```

---

# Cleanup

Remove the PostgreSQL cluster:

```bash
kubectl delete clusters.postgresql.cnpg.io pgvector-demo
```

Remove persistent storage (if the StorageClass is configured to retain the PVC):

```bash
kubectl delete pvc -l cnpg.io/cluster=pgvector-demo
```

If pgAdmin was deployed, remove it:

```bash
kubectl delete deployment/pgvector-demo-pgadmin4 \ 
  service/pgvector-demo-pgadmin4 \ 
  secret/pgvector-demo-pgadmin4 \ 
  configmap/pgvector-demo-pgadmin4
```

---

# File Overview

| File                                          | Description                                                         |
| --------------------------------------------- | ------------------------------------------------------------------- |
| `README.md`                                   | Deployment and usage instructions                                   |
| `kustomization.yaml`                          | Controls which resources NKP Continuous Deployment reconciles       |
| `helmrelease.yaml`                            | Flux HelmRelease that deploys the local Helm chart                  |
| `pgvector-demo.yaml`                          | Direct CloudNativePG Cluster manifest for manual kubectl deployment |
| `charts/pgvector-demo/Chart.yaml`             | Helm chart metadata                                                 |
| `charts/pgvector-demo/values.yaml`            | Default chart values                                                |
| `charts/pgvector-demo/templates/cluster.yaml` | Helm template for the CloudNativePG Cluster                         |

---

## 🧩 Related Links

* [CloudNativePG Documentation](https://cloudnative-pg.io/docs)
* [pgvector Documentation](https://github.com/pgvector/pgvector)
* [PostgreSQL Documentation](https://www.postgresql.org/docs/)
* [NKP Documentation](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Platform:Nutanix-Kubernetes-Platform)
