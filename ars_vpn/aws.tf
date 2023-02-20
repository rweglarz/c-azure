provider "aws" {
  region = "eu-central-1"
}

resource "aws_ec2_managed_prefix_list_entry" "left_u_hub_fw" {
  cidr           = "${module.left_u_hub_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-left-u-hub-fw"
}

resource "aws_ec2_managed_prefix_list_entry" "right_hub_fw" {
  cidr           = "${module.right_hub_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-right-hub-fw"
}

resource "aws_ec2_managed_prefix_list_entry" "left_u_ipsec_fw1" {
  cidr           = "${module.left_u_ipsec_fw1.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-left-u-ipsec-fw1"
}

resource "aws_ec2_managed_prefix_list_entry" "left_u_ipsec_fw2" {
  cidr           = "${module.left_u_ipsec_fw2.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-left-u-ipsec-fw2"
}

resource "aws_ec2_managed_prefix_list_entry" "right_env_fw2" {
  cidr           = "${module.right_env_fw1.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-right-env-fw1"
}
