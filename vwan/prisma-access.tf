resource "azurerm_vpn_site" "prisma-access" {
  for_each = var.prisma_access

  name                = "prisma-access-${random_id.did.hex}-${each.key}"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id

  dynamic "link" {
    for_each = each.value.links
    content {
      name       = link.key
      ip_address = link.value.public_ip
      bgp {
        asn             = link.value.asn
        peering_address = link.value.peering_address
      }
    }
  }
}

locals {
  hub2gateway = {
    hub2 = azurerm_vpn_gateway.hub2.id
    hub4 = azurerm_vpn_gateway.hub4.id
  }
  hub_site_links = flatten([
    for vsk,vsv in var.prisma_access: [
      for lk,lv in azurerm_vpn_site.prisma-access[vsk].link: [
        for hk,hv in var.prisma_access[vsk].links[lv.name].connect_to: {
          site = vsk
          link_name = lv.name
          link_id = lv.id
          link = var.prisma_access[vsk].links[lv.name]
          hub = hk
          vgw_id = local.hub2gateway[hk]
          hub_site_link = "${hk}-${vsk}-${lk}"
          hub_site = "${hk}-${vsk}"
        }
      ]
    ]
  ])
  hub_sites = {for hs in distinct(local.hub_site_links[*].hub_site): hs => [
    for hsl in local.hub_site_links: hsl if hsl.hub_site==hs
  ]}
}


resource "azurerm_vpn_gateway_connection" "prisma-access" {
  for_each = { for hsk,hsv in local.hub_sites: hsk=>hsv[0] } #there should be always at first element

  name               = "prisma-access-${random_id.did.hex}-${each.value.site}"
  vpn_gateway_id     = each.value.vgw_id
  remote_vpn_site_id = azurerm_vpn_site.prisma-access[each.value.site].id

  dynamic "vpn_link" {
    for_each = { for hslk,hslv in local.hub_site_links: hslv.link_name=>hslv if hslv.hub_site==each.key }
    content {
      name             = vpn_link.key
      vpn_site_link_id = each.value.link_id
      bgp_enabled      = true
      # custom_bgp_address {
      #   ip_address          = var.peering_address.hub2_i0[0]
      #   ip_configuration_id = "Instance0"
      # }
      # custom_bgp_address {
      #   ip_address          = var.peering_address.hub2_i0[1]
      #   ip_configuration_id = "Instance1"
      # }
      shared_key = vpn_link.value.link.psk
      protocol = try(vpn_link.value.link.protocol, null)
      dynamic "ipsec_policy" {
          # try specific policy, then common
          for_each = try({ x = vpn_link.value.link.ipsec_policy }, { x = var.prisma_access[each.value.site].ipsec_policy }, {})
          content {
            dh_group = ipsec_policy.value.dh_group
            ike_encryption_algorithm = ipsec_policy.value.ike_encryption_algorithm
            ike_integrity_algorithm = ipsec_policy.value.ike_integrity_algorithm
            encryption_algorithm  = ipsec_policy.value.encryption_algorithm
            integrity_algorithm = ipsec_policy.value.integrity_algorithm
            pfs_group = ipsec_policy.value.pfs_group
            sa_lifetime_sec = ipsec_policy.value.sa_lifetime_sec
            sa_data_size_kb = ipsec_policy.value.sa_data_size_kb
          }
      }
    }
  }
}
