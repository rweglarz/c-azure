resource "azurerm_dns_a_record" "appgw" {
  name                = "${var.name}-cn-appgw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    azurerm_public_ip.appgw.ip_address
  ]
}
