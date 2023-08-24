resource "aws_ec2_managed_prefix_list_entry" "cloud_ngfw_ips" {
  cidr           = "${var.cloud_ngfw_public_ip}/32"
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = "azure-cloud-ngfw-vnet"
}
