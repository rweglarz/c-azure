resource "azurerm_dns_a_record" "public" {
  for_each = {
    jumphost = module.jumphost.public_ip
    app11    = module.srv_app11.public_ip
    app12    = module.srv_app12.public_ip
    app2     = module.srv_app2.public_ip
    db1      = module.srv_db1.public_ip
    appgw1   = module.appgw1.public_ip_address
    appgw2   = module.appgw2.public_ip_address
  }
  name                = "vmss-m-${each.key}"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    each.value
  ]
}
