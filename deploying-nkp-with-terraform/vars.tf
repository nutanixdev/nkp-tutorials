// Prism Central credentials

variable "nutanix_username" {
  type        = string
  description = "This is the username for the Prism Central instance. Required for provider"
}

variable "nutanix_password" {
  type        = string
  description = "This is the password for the Prism Central instance. Required for provider"
  sensitive   = true
}

variable "nutanix_endpoint" {
  type        = string
  description = "This is the IP address or FQDN for the Prism Central instance. Required for provider"
}

variable "nutanix_port" {
  type        = number
  description = "This is the port for the Prism Central instance. Required for provider"
  default     = 9440
}

variable "nutanix_insecure" {
  type        = bool
  description = "This specifies whether to allow verify ssl certificates. Required for provider"
  default     = false
}

variable "nutanix_wait" {
  type        = number
  description = "This specifies the timeout on all resource operations in the provider in minutes. Required for provider"
  default     = 1
}

// Bastion VM

variable "bastion_vm_username" {
  type        = string
  description = "Username used for NKP installation."
  default     = "nutanix"
}

variable "bastion_vm_password" {
  type        = string
  description = "Password used for NKP installation."
  default     = "nutanix/4u"
  sensitive   = true
}

variable "nkp_image_url" {
  type        = string
  description = "Rocky Linux OS image URL required to deploy NKP Bastion VM. Recommendation: use the NKP Rocky OS URL provided in the Nutanix Portal"
}

variable "subnet_name" {
  type        = string
  description = "Subnet used for NKP deployment."
}

// NKP settings

variable "nkp_version" {
  type        = string
  description = "NKP cluster version"
  default     = "2.12.0"
}

variable "nkp_cluster_name" {
  type        = string
  description = "NKP cluster name"
  validation {
    condition     = can(regex("^[a-z](?:[a-z0-9-]*[a-z0-9])?$", var.nkp_cluster_name))
    error_message = "Invalid cluster name. Name must start with a lowercase letter followed by up to 39 lowercase letters, numbers, or hyphens, and cannot end with a hyphen."
  }
}

variable "nkp_cli_tarball_url" {
  type        = string
  description = "NKP for Linux tarball URL. Available in the Nutanix Portal"
}

variable "nkp_lb_addresspool" {
  type        = string
  description = "This is the IP address range for Load Balancing. Format: XXX.XXX.XXX.XXX-YYY.YYY.YYY.YYY"
}

variable "nkp_controlplane_vip" {
  type        = string
  description = "This is the IP address for Kubernetes API. Format: XXX.XXX.XXX.XXX"
  validation {
    condition     = can(regex("^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.nkp_controlplane_vip))
    error_message = "Invalid IP format. Expected: XXX.XXX.XXX.XXX."
  }
}

variable "nkp_prism_cluster_name" {
  type        = string
  description = "Prism Element cluster name."
}

variable "nkp_prism_storage_container" {
  type        = string
  description = "This is the Nutanix Storage Container where the requested Persistent Volume Claims will get their volumes created. You can enable things like compression and deduplication in a Storage Container. The recommendation is to create at least one storage container in Prism Element well identified for Kubernetes usage. This will facilitate the search of persistent volumes when the environment scales."
  default     = "SelfServiceContainer"
}

variable "registry_mirror_url" {
  type        = string
  description = "An internal registry mirror for pulling images"
}
