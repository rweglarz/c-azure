resource "azurerm_dns_a_record" "left-fw" {
  name                = "ars-left-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.left_hub_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "left-ipsec-fw1" {
  name                = "ars-left-ipsec-fw1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.left_ipsec_fw1.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "left-ipsec-fw2" {
  name                = "ars-left-ipsec-fw2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.left_ipsec_fw2.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "right-fw" {
  name                = "ars-right-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.right_hub_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "srv_left_11" {
  name                = "ars-left-srv-11"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.srv_left_11.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv_right_11" {
  name                = "ars-right-srv-11"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.srv_right_11.public_ip
  ]
}
