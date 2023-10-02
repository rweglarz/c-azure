resource "aws_ec2_managed_prefix_list_entry" "cloud_ngfw_ips" {
  cidr           = "${azurerm_public_ip.cloudngfw.ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-cloud-ngfw-vnet"
}
