provider "aws" {
  region = "eu-central-1"
}

resource "aws_ec2_managed_prefix_list_entry" "panka1" {
  cidr           = "${azurerm_public_ip.mgmt[0].ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-ha2-0"
}
resource "aws_ec2_managed_prefix_list_entry" "panka2" {
  cidr           = "${azurerm_public_ip.mgmt[1].ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-ha2-1"
}
