output "nkp_dashboard_access" {
  value = "Run the following command to retrieve the NKP dashboard access:\n\n\tssh ${var.bastion_vm_username}@${local.bastion_vm_ip} nkp get dashboard\n"
}
