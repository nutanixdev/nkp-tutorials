# 🧠 Running PostgreSQL + pgvector on NKP with CloudNativePG

This tutorial demonstrates how to quickly deploy PostgreSQL with the `pgvector` extension on a NKP Kubernetes cluster using CloudNativePG (CNPG). The deployment automatically creates a sample vector-enabled database with fake embeddings and similarity search examples.

This setup is designed for experimentation, demos, and RAG/vector-search proof-of-concepts running directly on Kubernetes.

> ✅ **Prerequisites**:
>
> * A running NKP Kubernetes cluster
> * `kubectl` access to the cluster
> * CloudNativePG Operator installed
>
> ⚠️ **NKP Ultimate Requirement**
>
> This example uses **NKP Projects Continuous Deployment** to deploy the manifest declaratively through GitOps.
>
> * **NKP Ultimate** → fully supported with Projects + Continuous Deployment
> * **NKP Pro** → supported by manually applying the manifest with `kubectl apply -f`

---

## 🚀 Deployment Instructions

### NKP Ultimate (Recommended)

With NKP Ultimate, the deployment can be fully managed through **NKP Projects Continuous Deployment** using a Git repository as the source of truth.

Instead of manually applying the manifest with `kubectl`, configure a Git source that points to the repository containing the `pgvector-demo.yaml` manifest.

This approach provides:

* GitOps-based continuous reconciliation
* Declarative lifecycle management
* Drift detection and remediation
* Multi-cluster deployment workflows
* Integration with NKP Projects

---

#### 🧩 Configure the Git Source

Navigate to:

```txt
Projects → Continuous Deployment → GitOps Sources
```

Create a new Git source with the following configuration:

| Field          | Value                                             |
| -------------- | ------------------------------------------------- |
| Name           | `pgvector-on-nkp-with-cnpg`                       |
| Repository URL | `https://github.com/nutanixdev/nkp-tutorials.git` |
| Git Ref Type   | `Branch`                                          |
| Branch Name    | `main`                                            |
| Path           | `./pgvector-on-nkp-with-cnpg`                     |

Once the Git source is configured, NKP Continuous Deployment will automatically:

1. Detect the CloudNativePG manifest
2. Deploy the PostgreSQL cluster
3. Enable the `pgvector` extension
4. Create the sample vector-enabled database
5. Continuously reconcile the deployment state

---

#### ⚙️ NKP Pro Alternative

If using NKP Pro, apply the manifest manually:

```bash
kubectl apply -f pgvector-demo.yaml
```

Wait for the PostgreSQL cluster to become ready:

```bash
kubectl get clusters.postgresql.cnpg.io
kubectl get pods
```

---

### 📄 What's Deployed

The manifest creates:

* A **CloudNativePG PostgreSQL cluster**
* A PostgreSQL database named `app`
* The **pgvector** PostgreSQL extension
* A sample **documents** table
* Fake vector embeddings for experimentation
* A **HNSW vector index** for similarity search

---

### 🧩 Example Cluster Manifest

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: pgvector-demo
spec:
  instances: 1

  imageName: ghcr.io/cloudnative-pg/postgresql:17-standard-trixie

  storage:
    size: 10Gi

  bootstrap:
    initdb:
      database: app
      owner: app

      postInitApplicationSQL:
        - "CREATE EXTENSION IF NOT EXISTS vector;"
        - |
          CREATE TABLE documents (
            id bigserial PRIMARY KEY,
            title text NOT NULL,
            content text NOT NULL,
            embedding vector(3)
          );
        - |
          INSERT INTO documents (title, content, embedding) VALUES
            (
              'Kubernetes backups',
              'Backups protect persistent application data.',
              '[0.10,0.20,0.30]'
            ),
            (
              'RAG architecture',
              'A RAG system retrieves context before generating answers.',
              '[0.11,0.19,0.31]'
            ),
            (
              'PostgreSQL recovery',
              'WAL archiving enables point-in-time recovery.',
              '[0.80,0.10,0.10]'
            ),
            (
              'Cluster autoscaling',
              'Autoscaling changes node capacity based on workload demand.',
              '[0.20,0.75,0.10]'
            );
        - |
          CREATE INDEX documents_embedding_hnsw_idx
          ON documents
          USING hnsw (embedding vector_cosine_ops);
```

---

## 🔎 Accessing the Database

Connect to PostgreSQL:

```bash
kubectl exec -it pgvector-demo-1 -- psql -d app
```

Verify the extension:

```sql
\dx
```

Verify the table:

```sql
\dt
```

Show all documents:

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

---

## 🖥 Optional pgAdmin Deployment

For a friendly UI experience, you can deploy pgAdmin using the CloudNativePG (`kubectl cnpg`) plugin.

> ⚠️ **Important**
>
> The `kubectl cnpg` plugin is not installed by default.
>
> Install it first before using the pgAdmin helper commands.

### Install the CNPG kubectl Plugin

#### macOS (Homebrew)

```bash
brew install cloudnative-pg/tap/cnpg
```

#### Linux / Generic Installation

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

## 🚀 Deploy pgAdmin

Deploy pgAdmin in desktop mode:

```bash
kubectl cnpg pgadmin4 --mode desktop pgvector-demo
```

Port-forward locally:

```bash
kubectl port-forward \
  \
  deployment/pgvector-demo-pgadmin4 \
  8080:80
```

Access:

```txt
http://localhost:8080
```

---

## 🧹 Cleanup

Remove the PostgreSQL cluster:

```bash
kubectl delete clusters.postgresql.cnpg.io pgvector-demo
```

Remove persistent storage:

```bash
kubectl delete pvc -l cnpg.io/cluster=pgvector-demo
```

Remove the namespace:

```bash
kubectl delete namespace pgvector
```

---

## 📁 File Overview

| File                 | Description                                    |
| -------------------- | ---------------------------------------------- |
| `pgvector-demo.yaml` | CloudNativePG PostgreSQL + pgvector deployment |
| `README.md`          | Deployment and usage instructions              |

---

## 🧩 Related Links

* [CloudNativePG Documentation](https://cloudnative-pg.io/docs)
* [pgvector Documentation](https://github.com/pgvector/pgvector)
* [PostgreSQL Documentation](https://www.postgresql.org/docs/)
* [NKP Documentation](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Platform:Nutanix-Kubernetes-Platform)
