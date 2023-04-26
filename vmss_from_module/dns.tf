resource "azurerm_dns_a_record" "jumphost" {
  name                = "vmss-m-jumphost"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.jumphost.public_ip
  ]
}

resource "azurerm_dns_a_record" "app1" {
  name                = "vmss-m-app1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.srv_app1.public_ip
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
