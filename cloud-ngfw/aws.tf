resource "aws_ec2_managed_prefix_list_entry" "cloud_ngfw_ips" {
  cidr           = "${azurerm_public_ip.cloud_ngfw.ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-cloud-ngfw-vnet"
}

resource "aws_ec2_managed_prefix_list_entry" "cloud_ngfw_snat" {
  count = var.cloud_ngfw_public_egress_ip_number

  cidr           = "${azurerm_public_ip.cloud_ngfw_snat[count.index].ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-cloud-ngfw-vnet-snat-${count.index}"
}
