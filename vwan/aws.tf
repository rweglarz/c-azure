resource "aws_ec2_managed_prefix_list_entry" "hub1_sec_fw" {
  cidr           = "${module.hub1_sec_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-hub1-sec-fw"
}

resource "aws_ec2_managed_prefix_list_entry" "hub2_sec_fw" {
  cidr           = "${module.hub2_sec_fw.mgmt_ip_address}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-${var.name}-hub2-sec-fw"
}
