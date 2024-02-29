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
  _site_links_by_id = flatten([
    for vsk,vsv in azurerm_vpn_site.prisma-access: [
        for lk,lv in azurerm_vpn_site.prisma-access[vsk].link: {
            site = vsk
            link = lv.name
            id = lv.id
            sitelink = "${vsk}-${lv.name}"
        }
    ]
  ])
  site_links_by_id = { for sid in local._site_links_by_id: sid.sitelink => sid.id }
}


resource "azurerm_vpn_gateway_connection" "prisma-access" {
  for_each = { for k,v in var.prisma_access: k=>v if (contains(v.connect_to, "hub2")) }

  name               = "prisma-access-${random_id.did.hex}-${each.key}"
  vpn_gateway_id     = azurerm_vpn_gateway.hub2.id
  remote_vpn_site_id = azurerm_vpn_site.prisma-access[each.key].id

  dynamic "vpn_link" {
    for_each = each.value.links
    content {
      name             = vpn_link.key
      vpn_site_link_id = local.site_links_by_id["${each.key}-${vpn_link.key}"]
      bgp_enabled      = true
      # custom_bgp_address {
      #   ip_address          = var.peering_address.hub2_i0[0]
      #   ip_configuration_id = "Instance0"
      # }
      # custom_bgp_address {
      #   ip_address          = var.peering_address.hub2_i0[1]
      #   ip_configuration_id = "Instance1"
      # }
      shared_key = vpn_link.value.psk
      protocol = try(vpn_link.value.protocol, null)
      dynamic "ipsec_policy" {
          # try specific policy, then common
          for_each = try({ x = vpn_link.value.ipsec_policy }, { x = each.value.ipsec_policy }, {})
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


resource "azurerm_vpn_gateway_connection" "hub4-prisma-access" {
  for_each = { for k,v in var.prisma_access: k=>v if (contains(v.connect_to, "hub4")) }

  name               = "prisma-access-${random_id.did.hex}-hub4-${each.key}"
  vpn_gateway_id     = azurerm_vpn_gateway.hub4.id
  remote_vpn_site_id = azurerm_vpn_site.prisma-access[each.key].id

  dynamic "vpn_link" {
    for_each = each.value.links
    content {
      name             = vpn_link.key
      vpn_site_link_id = local.site_links_by_id["${each.key}-${vpn_link.key}"]
      bgp_enabled      = true
      # custom_bgp_address {
      #   ip_address          = var.peering_address.hub2_i0[0]
      #   ip_configuration_id = "Instance0"
      # }
      # custom_bgp_address {
      #   ip_address          = var.peering_address.hub2_i0[1]
      #   ip_configuration_id = "Instance1"
      # }
      shared_key = vpn_link.value.psk
      protocol = try(vpn_link.value.protocol, null)
      dynamic "ipsec_policy" {
          # try specific policy, then common
          for_each = try({ x = vpn_link.value.ipsec_policy }, { x = each.value.ipsec_policy }, {})
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
