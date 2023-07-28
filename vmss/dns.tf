resource "azurerm_dns_a_record" "jumphost" {
  name                = "vmss-jumphost"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.jumphost.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv_spoke_a_1" {
  name                = "vmss-srv-spoke-a-1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.srv_spoke_a_1.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv_spoke_a_2" {
  name                = "vmss-srv-spoke-a-2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.srv_spoke_a_1.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv_spoke_b_1" {
  name                = "vmss-srv-spoke-b-1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.srv_spoke_b_1.public_ip
  ]
}
