resource "azurerm_dns_a_record" "jumphost" {
  name                = "vmss-m-jumphost"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.jumphost.public_ip
  ]
}

resource "azurerm_dns_a_record" "app11" {
  name                = "vmss-m-app11"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.srv_app11.public_ip
  ]
}

resource "azurerm_dns_a_record" "app12" {
  name                = "vmss-m-app12"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.srv_app12.public_ip
  ]
}

resource "azurerm_dns_a_record" "db1" {
  name                = "vmss-m-db1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.srv_db1.public_ip
  ]
}

resource "azurerm_dns_a_record" "app2" {
  name                = "vmss-m-app2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.srv_app2.public_ip
  ]
}

resource "azurerm_dns_a_record" "appgw1" {
  name                = "vmss-m-appgw1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.appgw1.public_ip_address
  ]
}

resource "azurerm_dns_a_record" "appgw2" {
  name                = "vmss-m-appgw2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.appgw2.public_ip_address
  ]
}
