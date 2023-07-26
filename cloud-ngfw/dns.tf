resource "azurerm_dns_a_record" "app01-srv1" {
  name                = "${var.name}-app01-srv1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.app01_srv1.public_ip
  ]
}

resource "azurerm_dns_a_record" "app02-srv1" {
  name                = "${var.name}-app02-srv1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.app02_srv1.public_ip
  ]
}
