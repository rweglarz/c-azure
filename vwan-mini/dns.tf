resource "azurerm_dns_a_record" "this" {
  for_each = {
    uvwan-onprem      = module.linux_onprem.public_ip
    uvwan-hub1-spoke1 = module.linux_hub1_spoke1.public_ip
    uvwan-hub2-spoke1 = module.linux_hub2_spoke1.public_ip
    uvwan-hub1-sdwan1 = module.linux_hub1_sdwan[0].public_ip
    uvwan-hub1-sdwan2 = module.linux_hub1_sdwan[1].public_ip
  }
  name = each.key
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    each.value
  ]
}
