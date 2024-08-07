resource "azurerm_dns_a_record" "this" {
  for_each = {
    fw0   = module.fw.fw0.mgmt_ip_address
    fw1   = module.fw.fw1.mgmt_ip_address
    srv0  = module.spoke0_h.public_ip
    srv1  = module.spoke1_h.public_ip
    vpn   = module.vpn_h.public_ip
  }
  name                = "fast-ha-${each.key}"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 120
  records = [
    each.value
  ]
}
