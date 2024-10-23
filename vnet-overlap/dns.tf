resource "azurerm_dns_a_record" "this" {
  for_each = {
    overlap-sec1      = module.sec_1.public_ip
    # overlap-net1-u    = module.net1_unique.public_ip
    # overlap-net2-u    = module.net2_unique.public_ip
  }
  name = each.key
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 90
  records = [
    each.value
  ]
}
