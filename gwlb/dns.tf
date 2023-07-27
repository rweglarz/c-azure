resource "azurerm_dns_a_record" "jumphost" {
  name                = "gwlb-jumphost"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.jumphost.public_ip
  ]
}

resource "azurerm_dns_a_record" "sa" {
  name                = "gwlb-srv-sa"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    module.srv_sa.public_ip
  ]
}
