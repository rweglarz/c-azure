resource "azurerm_dns_a_record" "left-u-hub-fw" {
  name                = "ars-left-u-hub-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.left_u_hub_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "left-u-ipsec-fw1" {
  name                = "ars-left-u-ipsec-fw1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.left_u_ipsec_fw1.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "left-u-ipsec-fw2" {
  name                = "ars-left-u-ipsec-fw2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.left_u_ipsec_fw2.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "right-hub-fw" {
  name                = "ars-right-hub-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.right_hub_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "right-env-fw1" {
  name                = "ars-right-env-fw1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.right_env_fw1.mgmt_ip_address
  ]
}


resource "azurerm_dns_a_record" "left_u_srv11" {
  name                = "ars-left-u-srv11"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.linux_left_srv11.public_ip
  ]
}

resource "azurerm_dns_a_record" "right_srv11" {
  name                = "ars-right-srv11"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.linux_right_srv11.public_ip
  ]
}

resource "azurerm_dns_a_record" "right_env1_sdgw" {
  for_each            = module.linux_right_env1_sdgw
  name                = format("ars-right-%s", replace(each.key, "_", "-"))
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    each.value.public_ip
  ]
}

