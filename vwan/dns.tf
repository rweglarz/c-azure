resource "azurerm_dns_a_record" "aws-fw-1" {
  name                = "vwan-aws-fw-1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    one([for k, v in module.vm-fw-1.public_ips : v if(length(regexall("mgmt", k)) > 0)])
  ]
}
