<!-- omit in toc -->
# Deploying an NKP Management Cluster with Terraform

<!-- omit in toc -->
## Table of Contents
- [Overview](#overview)
- [Prerequisites Checklist](#prerequisites-checklist)
- [Deployment](#deployment)
- [Access the NKP dashboard](#access-the-nkp-dashboard)

## Overview

This example showcases one of the many possible approaches for automating the deployment of the first NKP management cluster using Terraform.

## Prerequisites Checklist

- Terraform installed (OpenTofu as an alternative)
- Internet connectivity
- URL for the Rocky Linux OS image available in the Nutanix Support Portal
- URL for the NKP CLI available in the Nutanix Support Portal
- Static IP address for the Kubernetes control plane VIP
- One or more IP addresses for the NKP dashboard and load-balancing service

## Deployment

This automation manifest will upload the Rocky Linux image to Prism Central if it doesn't already exist and then create the NKP management cluster.

**Note**: Destroying the deployment will destroy the bastion VM and the NKP management cluster.

1. Clone this repository

    ```console
    git clone https://github.com/nutanixdev/nkp-tutorials.git
    ```

2. Move into the tutorial folder

    ```console
    cd deploying-nkp-with-terraform
    ```

4. Rename the `nkp-cluster-config.auto.tfvars.example` to `nkp-cluster-config.auto.tfvars` and update its values

    ```console
    mv nkp-cluster-config.auto.tfvars.example nkp-cluster-config.auto.tfvars

    vi nkp-cluster-config.auto.tfvars
    # update values
    ```

5. Apply the manifest and confirm

    ```console
    terraform init
    terraform apply
    # enter "yes", if ready
    ```

6. A successful deployment will show a message like:

    ```console
    [...]
    Run the following command to retrieve the NKP dashboard access:

            ssh <bastion_username>@<your_bastion_vm_ip> nkp get dashboard
    [...]
    ```

## Access the NKP dashboard

Execute the output command to get the connection details for the NKP dashboard. Replace the `bastion_username` and `your_bastion_vm_ip` with the output from the deployment.

```console
ssh <bastion_username>@<your_bastion_vm_ip> nkp get dashboard
```

The connection details will look something similar to the following:

```console
Username: hopeful_proskuriakova
Password: umlTEP1bxCcpjVRjlMiGn89w8009MMx6aMJVZOhVtz5LuPYgYbbmEtuu8VLPgpGt
URL: https://192.168.0.12/dkp/kommander/dashboard
```
