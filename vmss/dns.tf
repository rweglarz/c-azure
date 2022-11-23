resource "azurerm_dns_a_record" "jumphost" {
  name                = "vmss-jumphost"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    azurerm_public_ip.jumphost.ip_address
  ]
}
