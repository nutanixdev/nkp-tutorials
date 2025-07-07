# 🧠 Running LocalAI Inference on Kubernetes with NKP

This tutorial demonstrates how to quickly deploy [LocalAI](https://localai.io/) on a NKP Kubernetes cluster using a single command. This setup includes a PersistentVolumeClaim for model storage and exposes the inference server via Traefik Ingress with a public-friendly URL using `sslip.io`.

> ✅ **Prerequisites**: A running NKP Kubernetes cluster with `kubectl`.

---

## 🚀 Deployment Instructions

You can deploy LocalAI in seconds using the following command:

```bash
curl -sSL https://localai-nkp.nutanixdemo.com | bash
```

This script will:

1. Apply a Kubernetes manifest that sets up LocalAI under the `localai` namespace.
2. Wait for the LocalAI deployment to become ready.
3. Automatically detect your Ingress controller's external IP.
4. Print the accessible URL to reach the LocalAI inference endpoint at `/localai`.

---

## 📄 What's Deployed

The manifest (`aio.yaml`) creates:

* A **namespace** named `localai`
* A **PersistentVolumeClaim** named `models-pvc` for storing model data
* A **Deployment** that runs the `localai` container using `quay.io/go-skynet/local-ai:latest-cpu`
* A **ClusterIP Service** to expose the container on port 8080 internally
* A **Traefik Ingress** and **IngressRoute** to route `/localai` requests
* A **Traefik Middleware** to redirect requests to a user-friendly `sslip.io` subdomain

---

## 🌐 Accessing the Inference Endpoint

Once deployed, the script will display a URL like:

```
http://<INGRESS-IP>/localai
```

The Traefik middleware will also redirect to:

```
https://localai.<INGRESS-IP>.sslip.io/
```

---

## 🧹 Cleanup

To remove the deployment:

```bash
kubectl delete namespace localai
```

---

## 📁 File Overview

| File                | Description                                     |
| ------------------- | ----------------------------------------------- |
| `aio.yaml`          | Kubernetes manifest with full LocalAI setup     |
| `deploy-localai.sh` | Script to automate the deployment and print URL |

---

## 🧩 Related Links

* [LocalAI Documentation](https://localai.io/)
