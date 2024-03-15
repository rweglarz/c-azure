resource "azurerm_dns_a_record" "this" {
  for_each = {
    sds-spoke1 = module.linux_spoke1.public_ip
    sds-spoke2 = module.linux_spoke2.public_ip
    sds-sdwan1 = module.linux_sdwan1.public_ip
    sds-sdwan2 = module.linux_sdwan2.public_ip
  }
  name = each.key
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    each.value
  ]
}
