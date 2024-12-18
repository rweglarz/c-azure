resource "azurerm_dns_a_record" "this" {
  for_each = {
    "${local.dns_prefix}-fw0"  = azurerm_public_ip.mgmt[0].ip_address
    "${local.dns_prefix}-fw1"  = azurerm_public_ip.mgmt[1].ip_address
    "${local.dns_prefix}-srv0" = module.vm_sec_srv0.public_ip
    "${local.dns_prefix}-srv1" = module.vm_sec_srv1.public_ip
    "${local.dns_prefix}-srv5" = module.vm_peered_srv5.public_ip
    "${local.dns_prefix}-srv6" = module.vm_peered_srv6.public_ip
    "${local.dns_prefix}-pub-main" = azurerm_public_ip.untrust["main"].ip_address
  }
  name                = each.key
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    each.value
  ]
}
