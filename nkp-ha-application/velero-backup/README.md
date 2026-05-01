

# Velero Installation on NKP with Nutanix Objects S3 Backend

---

## 1. Create the cloud credentials Secret

Replace `xyz` with your actual bucket access credentials.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloud-credentials
  namespace: kommander  
type: Opaque
stringData:
  cloud: |
    [default]
    aws_access_key_id = xyz
    aws_secret_access_key = xyz
```

---

## 2. Apply the Velero Override Configuration

Replace `xyz` with your Nutanix Objects IP address or FQDN.

```yaml
configuration:
  backupStorageLocation:
    - bucket: nkp-velero
      config:
        region: us-east-1
        s3Url: https://xyz:443
        s3ForcePathStyle: true
        insecureSkipTLSVerify: true
        profile: default 
      provider: aws
      credential:
        key: cloud
        name: cloud-credentials
  features: EnableCSI
  uploaderType: kopia
  volumeSnapshotLocation:
    - bucket: nkp-velero
      config:
        region: us-east-1
        s3Url: https://xyz:443
      provider: aws
deployNodeAgent: true
initContainers:
  - image: velero/velero-plugin-for-aws:v1.7.0
    imagePullPolicy: IfNotPresent
    name: velero-plugin-for-aws
    volumeMounts:
      - mountPath: /target
        name: plugins
nodeAgent:
  annotations:
    secret.reloader.stakater.com/reload: cloud-credentials
  priorityClassName: dkp-critical-priority
  resources:
    limits: null
```

---
