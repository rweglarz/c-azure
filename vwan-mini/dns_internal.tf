resource "azurerm_private_dns_zone" "this" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_private_dns_zone" "pl" {
  for_each = local.private_link_services
  name                = each.value.dns_zone
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_a_record" "this" {
  for_each = merge(
    {
      hub1-spoke1  = module.linux_hub1_spoke1.private_ip_address,
      hub1-spoke2  = module.linux_hub1_spoke2.private_ip_address,
      hub2-spoke1  = module.linux_hub2_spoke1.private_ip_address,
      hub2-spoke2  = module.linux_hub2_spoke2.private_ip_address,
    },
    {
      for k,v in azurerm_private_endpoint.pl_app: replace("${var.name}-${k}-pl", "-", "") => v.private_service_connection[0].private_ip_address
    }
  )
  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
  zone_name           = azurerm_private_dns_zone.this.name
  ttl                 = local.dns_ttl
  records = [
    each.value
  ]
}

locals {
  vnets_to_dns_zones_l = flatten([
    for vnet_k,vnet_v in local.vnets_with_private_dns: [
      for pl_k,pl_v in local.private_link_services: {
        key      = format("%s_%s", vnet_k, pl_k)
        vnet_id  = vnet_v
        dns_zone = pl_v.dns_zone
      }
    ]
  ])
  vnets_to_dns_zones = { for k,v in local.vnets_to_dns_zones_l: v.key => v }
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.vnets_with_private_dns

  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value
}

resource "azurerm_private_dns_zone_virtual_network_link" "pl" {
  for_each = local.vnets_to_dns_zones

  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = each.value.dns_zone
  virtual_network_id    = each.value.vnet_id
}
