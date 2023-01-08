resource "aws_ec2_managed_prefix_list_entry" "hub1_sec_fw" {
  cidr           = "${module.hub1_sec_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub1-sec-fw"
}

resource "aws_ec2_managed_prefix_list_entry" "hub2_sec_fw" {
  cidr           = "${module.hub2_sec_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub2-sec-fw"
}

resource "aws_ec2_managed_prefix_list_entry" "hub2_sdwan_fw1" {
  cidr           = "${module.hub2_sdwan_fw1.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub2_sdwan_fw1"
}

resource "aws_ec2_managed_prefix_list_entry" "hub2_sdwan_fw2" {
  cidr           = "${module.hub2_sdwan_fw2.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-hub2_sdwan_fw2"
}

resource "aws_ec2_managed_prefix_list_entry" "sdwan_spoke1_fw" {
  cidr           = "${module.sdwan_spoke1_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${local.dname}-sdwan_spoke1_fw"
}
