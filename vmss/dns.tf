resource "azurerm_dns_a_record" "this" {
  for_each = {
    jumphost  = module.jumphost.public_ip
    app1      = module.servers["app1"].public_ip
    app2      = module.servers["app2"].public_ip
    dmz       = module.servers["dmz"].public_ip
  }
  name = "vmss-${each.key}"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 180
  records = [
    each.value
  ]
}
