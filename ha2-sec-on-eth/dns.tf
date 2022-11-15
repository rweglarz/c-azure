resource "azurerm_dns_a_record" "fw" {
  count = 2
  name                = "${var.name}-fw${count.index}"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    azurerm_public_ip.mgmt[count.index].ip_address
  ]
}

resource "azurerm_dns_a_record" "srv0" {
  name                = "${var.name}-srv0"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.srv0.public_ip
  ]
}
resource "azurerm_dns_a_record" "srv1" {
  name                = "${var.name}-srv1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.srv1.public_ip
  ]
}

resource "azurerm_dns_a_record" "srv5" {
  name                = "${var.name}-srv5"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.srv5.public_ip
  ]
}
resource "azurerm_dns_a_record" "srv6" {
  name                = "${var.name}-srv6"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    module.srv6.public_ip
  ]
}

