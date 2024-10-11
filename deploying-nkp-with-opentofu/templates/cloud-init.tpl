#cloud-config

# set the hostname
fqdn: ${hostname}

ssh_pwauth: true
chpasswd:
  expire: false
  users:
  - name: ${bastion_vm_username}
    password: ${bastion_vm_password} # Recommended to change the password or update the script to use SSH keys
    type: text
bootcmd:
- mkdir -p /etc/docker
write_files:
- content: |
    {
        "insecure-registries": ["${registry_mirror_url}"]
    }
  path: /etc/docker/daemon.json
runcmd:
- '[ ! -f "/etc/yum.repos.d/nutanix_rocky9.repo" ] || mv -f /etc/yum.repos.d/nutanix_rocky9.repo /etc/yum.repos.d/nutanix_rocky9.repo.disabled'
- dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
- dnf -y install docker-ce docker-ce-cli containerd.io
- systemctl --now enable docker
- usermod -aG docker ${bastion_vm_username}
- 'curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl'
- chmod +x /usr/local/bin/kubectl
- 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash'
- 'curl -fsSL "${nkp_cli_tarball_url}" | sudo tar xz -C /usr/local/bin -- nkp'
- eject
