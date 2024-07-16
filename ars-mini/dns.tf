resource "azurerm_dns_a_record" "this" {
  for_each = {
    fw      = module.linux_fw.public_ip
    sdgw_A1 = module.linux_sdgw.sdgw_A1.public_ip
    sdgw_A2 = module.linux_sdgw.sdgw_A2.public_ip
    sdgw_B  = module.linux_sdgw.sdgw_B.public_ip
  }
  name                = format("ars-mini-%s", replace(each.key, "_", "-"))
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    each.value
  ]
}
