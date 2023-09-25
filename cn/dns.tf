resource "azurerm_dns_a_record" "appgw1" {
  name                = "${var.name}-cn-appgw1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.appgw1.public_ip_address
  ]
}
