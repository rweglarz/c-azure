resource "azurerm_dns_a_record" "h1" {
  name                = "plugin-h1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.h1.public_ip
  ]
}

resource "azurerm_dns_a_record" "h2" {
  name                = "plugin-h2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.h2.public_ip
  ]
}
