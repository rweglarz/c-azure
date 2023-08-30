resource "aws_ec2_managed_prefix_list_entry" "hub1_sec_fw" {
  cidr           = "${module.hub1_sec_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub1-sec-fw"
}

resource "aws_ec2_managed_prefix_list_entry" "hub2_sdwan_fw" {
  cidr           = "${module.hub2_sdwan_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub2_sdwan_fw"
}

resource "aws_ec2_managed_prefix_list_entry" "hub4_sdwan_fw" {
  cidr           = "${module.hub4_sdwan_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub4_sdwan_fw"
}

resource "aws_ec2_managed_prefix_list_entry" "sdwan_spoke1_fw" {
  cidr           = "${module.sdwan_spoke1_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-sdwan_spoke1_fw"
}

resource "aws_ec2_managed_prefix_list_entry" "ipsec_spoke1_fw" {
  cidr           = "${module.ipsec_spoke1_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-ipsec_spoke1_fw"
}

resource "aws_ec2_managed_prefix_list_entry" "ipsec_hub1_fw1" {
  cidr           = "${module.ipsec_hub2_fw1.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub1-fw1"
}

resource "aws_ec2_managed_prefix_list_entry" "ipsec_hub1_fw2" {
  cidr           = "${module.ipsec_hub2_fw2.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub1-fw2"
}

resource "aws_ec2_managed_prefix_list_entry" "cloud_ngfw_hub2" {
  cidr           = "${azurerm_public_ip.hub2_fw.ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-cloud-ngfw-hub2"
}

resource "aws_ec2_managed_prefix_list_entry" "cloud_ngfw_hub4" {
  cidr           = "${azurerm_public_ip.hub4_fw.ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-cloud-ngfw-hub4"
}
