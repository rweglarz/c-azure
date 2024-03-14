resource "aws_ec2_managed_prefix_list_entry" "this" {
  for_each = {
    "${var.name}-hub1-natgw" = "${azurerm_public_ip.hub1_natgw.ip_address}/32"
  }
  cidr           = each.value
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  description    = each.key
}
