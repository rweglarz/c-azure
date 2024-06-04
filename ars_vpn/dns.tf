resource "azurerm_dns_a_record" "this" {
  for_each = {
    ars-left-u-hub-fw    = module.left_u_hub_fw["1"].mgmt_ip_address
    ars-left-u-ipsec-fw1 = module.left_u_ipsec_fw1.mgmt_ip_address
    ars-left-u-ipsec-fw2 = module.left_u_ipsec_fw2.mgmt_ip_address
    ars-left-b-hub-fw    = module.left_b_hub_fw["1"].mgmt_ip_address
    ars-left-b-ipsec-fw1 = module.left_b_ipsec_fw1.mgmt_ip_address
    ars-left-b-ipsec-fw2 = module.left_b_ipsec_fw2.mgmt_ip_address
    ars-right-hub-fw     = module.right_hub_fw.mgmt_ip_address
    ars-right-env-fw1    = module.right_env_fw1.mgmt_ip_address
    ars-left-u-srv11     = module.linux_left_u_srv11.public_ip
    ars-left-b-srv11     = module.linux_left_b_srv11.public_ip
    ars-right-srv11      = module.linux_right_srv11.public_ip
  }
  name                = each.key
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    each.value
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

