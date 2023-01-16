resource "azurerm_dns_a_record" "jumphost" {
  name                = "vmss-jumphost"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.jumphost.public_ip
  ]
}
