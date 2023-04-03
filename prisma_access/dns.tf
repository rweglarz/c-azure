resource "azurerm_dns_a_record" "jumphost" {
  name                = "pa-jumphost"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.jumphost.public_ip
  ]
}

resource "azurerm_dns_a_record" "panorama" {
  name                = "pa-panorama"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.panorama.mgmt_ip_address
  ]
}
