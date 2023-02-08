provider "aws" {
  region = "eu-central-1"
}

resource "aws_ec2_managed_prefix_list_entry" "left_hub_fw" {
  cidr           = "${module.left_hub_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-left-hub-fw"
}

resource "aws_ec2_managed_prefix_list_entry" "right_hub_fw" {
  cidr           = "${module.right_hub_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-right-hub-fw"
}

resource "aws_ec2_managed_prefix_list_entry" "left_ipsec_fw1" {
  cidr           = "${module.left_ipsec_fw1.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-left-ipsec-fw1"
}

resource "aws_ec2_managed_prefix_list_entry" "left_ipsec_fw2" {
  cidr           = "${module.left_ipsec_fw2.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-left-ipsec-fw2"
}
