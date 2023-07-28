resource "azurerm_dns_a_record" "jumphost" {
  name                = "vmss-jumphost"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.jumphost.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv_spoke_a_11" {
  name                = "vmss-srv-spoke-a-11"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.srv_spoke_a_11.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv_spoke_a_12" {
  name                = "vmss-srv-spoke-a-12"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.srv_spoke_a_12.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv_spoke_a_2" {
  name                = "vmss-srv-spoke-a-2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.srv_spoke_a_2.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv_spoke_b_1" {
  name                = "vmss-srv-spoke-b-1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.srv_spoke_b_1.public_ip
  ]
}
