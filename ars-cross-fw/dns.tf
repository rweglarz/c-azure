resource "azurerm_dns_a_record" "this" {
  for_each = { for k, v in module.vm_linux: k => v.public_ip if v.public_ip!=null }
  name                = format("ars-cfw-%s", replace(each.key, "_", "-"))
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    each.value
  ]
}

resource "azurerm_dns_a_record" "avs" {
  name                = "ars-cfw-avs"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    azurerm_public_ip.avs.ip_address
  ]
}
