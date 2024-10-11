terraform {
  required_providers {
    nutanix = {
      source  = "terraform-providers/nutanix"
      version = "~> 1.9.5"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.3"
    }
  }
  required_version = ">= 0.13"
}

provider "nutanix" {
  username     = var.nutanix_username
  password     = var.nutanix_password
  endpoint     = var.nutanix_endpoint
  port         = var.nutanix_port
  insecure     = var.nutanix_insecure
  wait_timeout = var.nutanix_wait
}

locals {
  cluster_uuid   = data.nutanix_subnet.vlan.cluster_uuid
  nkp_image_name = basename(var.nkp_image_url)
  bastion_vm_ip  = nutanix_virtual_machine.bastion_vm.nic_list_status.0.ip_endpoint_list.0.ip
}

data "template_file" "bastion_vm_cloud-init" {
  template = file("${path.module}/templates/cloud-init.tpl")
  vars = {
    hostname            = "${var.nkp_cluster_name}-nkp-bastion"
    bastion_vm_username = var.bastion_vm_username
    bastion_vm_password = var.bastion_vm_password
    nkp_cli_tarball_url = var.nkp_cli_tarball_url
    registry_mirror_url = var.registry_mirror_url
  }
}

data "nutanix_subnet" "vlan" {
  subnet_name = var.subnet_name
}

data "nutanix_cluster" "cluster" {
  cluster_id = local.cluster_uuid
}

data "nutanix_image" "nkp_image" {
  image_name = local.nkp_image_name
}

resource "nutanix_image" "nkp_image" {
  count       = length(data.nutanix_image.nkp_image.id) == 0 ? 1 : 0
  name        = local.nkp_image_name
  source_uri  = var.nkp_image_url
  description = "OS image for NKP bastion VM uploaded via OpenTofu/Terraform"
  image_type  = "DISK_IMAGE"
}

resource "nutanix_virtual_machine" "bastion_vm" {
  name                 = "${var.nkp_cluster_name}-nkp-bastion"
  cluster_uuid         = local.cluster_uuid
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 4 * 1024
  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = data.nutanix_image.nkp_image.id
    }
    device_properties {
      device_type = "DISK"
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }
    }
    disk_size_bytes = 131072 * 1024 * 1024
  }
  guest_customization_cloud_init_user_data = base64encode(data.template_file.bastion_vm_cloud-init.rendered)
  nic_list {
    subnet_uuid = data.nutanix_subnet.vlan.id
  }

  connection {
    user     = var.bastion_vm_username
    password = var.bastion_vm_password
    host     = self.nic_list_status[0].ip_endpoint_list[0].ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait >/dev/null 2>&1"
    ]
  }

  provisioner "file" {
    destination = "variables.sh"
    content     = <<-EOF
      export NO_COLOR=1
      export CLUSTER_NAME=${var.nkp_cluster_name}
      export CONTROL_PLANE_ENDPOINT_IP=${var.nkp_controlplane_vip}
      export LB_IP_RANGE=${var.nkp_lb_addresspool}
      export NKP_VERSION=${var.nkp_version}
      export NUTANIX_ENDPOINT=${var.nutanix_endpoint}
      export NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME=${local.nkp_image_name}
      export NUTANIX_PASSWORD='${var.nutanix_password}'
      export NUTANIX_PORT=${var.nutanix_port}
      export NUTANIX_PRISM_ELEMENT_CLUSTER_NAME=${var.nkp_prism_cluster_name}
      export NUTANIX_STORAGE_CONTAINER_NAME=${var.nkp_prism_storage_container}
      export NUTANIX_SUBNET_NAME=${var.subnet_name}
      export NUTANIX_USER=${var.nutanix_username}
      export REGISTRY_MIRROR_URL=${var.registry_mirror_url}
    EOF
  }
}

resource "null_resource" "nkp_create_cluster" {
  triggers = {
    bastion_vm_ip       = local.bastion_vm_ip
    bastion_vm_username = var.bastion_vm_username
    bastion_vm_password = var.bastion_vm_password
  }

  connection {
    user     = self.triggers.bastion_vm_username
    password = self.triggers.bastion_vm_password
    host     = self.triggers.bastion_vm_ip
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/nkp_create_cluster.sh"
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "source ~/variables.sh",
      "nkp delete cluster -c $CLUSTER_NAME --self-managed"
    ]
  }
}
