resource "panos_panorama_template" "azure_ha2" {
  name = "azure-ha2"
}
resource "panos_panorama_template_stack" "azure_ha2_0" {
  name         = "azure-ha2-0"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_ha2.name,
    "azure-ha2-rg",
    "vm-ha-ha2-eth1-1",
    "vm common",
  ]
}
resource "panos_panorama_template_stack" "azure_ha2_1" {
  name         = "azure-ha2-1"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_ha2.name,
    "azure-ha2-rg",
    "vm-ha-ha2-eth1-1",
    "vm common",
  ]
}

resource "panos_panorama_management_profile" "azure_ha2_ping" {
  template = panos_panorama_template.azure_ha2.name
  name     = "ping"
  ping     = true
}
resource "panos_panorama_ethernet_interface" "azure_ha2_eth1_2" {
  template = panos_panorama_template.azure_ha2.name
  name     = "ethernet1/2"
  vsys     = "vsys1"
  mode     = "layer3"
  static_ips = [
    "${azurerm_network_interface.data[1].ip_configuration[1].private_ip_address}/28"
  ]
  enable_dhcp = false

  management_profile = panos_panorama_management_profile.azure_ha2_ping.name
}
/*
resource "panos_arp" "azure_ha2_eth1_2_dg" {
  template       = panos_panorama_template.azure_ha2.name
  interface_type = "ethernet"
  interface_name = panos_panorama_ethernet_interface.azure_ha2_eth1_2.name
  ip             = cidrhost(azurerm_subnet.data[1].address_prefixes[0], 1)
  mac_address    = "12:34:56:78:9a:bc"
}
*/
resource "panos_panorama_loopback_interface" "azure_ha2_lo2" {
  template = panos_panorama_template.azure_ha2.name
  name     = "loopback.2"
  static_ips = [
    "${azurerm_network_interface.data[1].ip_configuration[0].private_ip_address}/32",
    "${azurerm_network_interface.data[4].ip_configuration[0].private_ip_address}/32",
  ]
  management_profile = panos_panorama_management_profile.azure_ha2_ping.name
}


resource "panos_panorama_ethernet_interface" "azure_ha2_eth1_3" {
  template    = panos_panorama_template.azure_ha2.name
  name        = "ethernet1/3"
  vsys        = "vsys1"
  mode        = "layer3"
  static_ips  = [
    "${azurerm_network_interface.data[2].ip_configuration[1].private_ip_address}/28",
  ]
  enable_dhcp = false

  management_profile = panos_panorama_management_profile.azure_ha2_ping.name
}

resource "panos_panorama_loopback_interface" "azure_ha2_lo3" {
  template = panos_panorama_template.azure_ha2.name
  name     = "loopback.3"
  static_ips = [
    "${azurerm_network_interface.data[2].ip_configuration[0].private_ip_address}/32",
    "${azurerm_network_interface.data[5].ip_configuration[0].private_ip_address}/32",
  ]
  management_profile = panos_panorama_management_profile.azure_ha2_ping.name
}

resource "panos_zone" "azure_ha2_internet" {
  template = panos_panorama_template.azure_ha2.name
  name     = "internet"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.azure_ha2_eth1_2.name,
    panos_panorama_loopback_interface.azure_ha2_lo2.name,
  ]
}
resource "panos_zone" "azure_ha2_servers" {
  template = panos_panorama_template.azure_ha2.name
  name     = "servers"
  mode     = "layer3"
  interfaces = [
    panos_panorama_ethernet_interface.azure_ha2_eth1_3.name,
    panos_panorama_loopback_interface.azure_ha2_lo3.name,
  ]
}
resource "panos_virtual_router" "ha2_vr1" {
  name     = "vr1"
  template = panos_panorama_template.azure_ha2.name
  interfaces = [
    panos_panorama_ethernet_interface.azure_ha2_eth1_2.name,
    panos_panorama_ethernet_interface.azure_ha2_eth1_3.name,
    panos_panorama_loopback_interface.azure_ha2_lo2.name,
    panos_panorama_loopback_interface.azure_ha2_lo3.name,
  ]
}
resource "panos_panorama_static_route_ipv4" "ha2_vr1_dg" {
  template       = panos_panorama_template.azure_ha2.name
  virtual_router = panos_virtual_router.ha2_vr1.name
  name           = "internet"
  destination    = "0.0.0.0/0"
  next_hop       = cidrhost(azurerm_subnet.data[1].address_prefixes[0], 1)
  interface      = panos_panorama_ethernet_interface.azure_ha2_eth1_2.name
}
resource "panos_panorama_static_route_ipv4" "ha2_vr1_private" {
  template       = panos_panorama_template.azure_ha2.name
  virtual_router = panos_virtual_router.ha2_vr1.name
  name           = "private"
  destination    = "172.16.0.0/12"
  next_hop       = cidrhost(azurerm_subnet.data[2].address_prefixes[0], 1)
  interface      = panos_panorama_ethernet_interface.azure_ha2_eth1_3.name
}



resource "panos_panorama_template_variable" "ha0-ha1_peer_ip" {
  template_stack = panos_panorama_template_stack.azure_ha2_0.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = azurerm_network_interface.mgmt[1].ip_configuration[0].private_ip_address
}
resource "panos_panorama_template_variable" "ha1-ha1_peer_ip" {
  template_stack = panos_panorama_template_stack.azure_ha2_1.name
  name           = "$ha1-peer-ip"
  type           = "ip-netmask"
  value          = azurerm_network_interface.mgmt[0].ip_configuration[0].private_ip_address
}
resource "panos_panorama_template_variable" "ha0-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.azure_ha2_0.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = azurerm_network_interface.data[0].ip_configuration[0].private_ip_address
}
resource "panos_panorama_template_variable" "ha1-ha2_local_ip" {
  template_stack = panos_panorama_template_stack.azure_ha2_1.name
  name           = "$ha2-local-ip"
  type           = "ip-netmask"
  value          = azurerm_network_interface.data[3].ip_configuration[0].private_ip_address
}
resource "panos_panorama_template_variable" "ha0-ha2_gw" {
  template_stack = panos_panorama_template_stack.azure_ha2_0.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(azurerm_subnet.data[0].address_prefixes[0], 1)
}
resource "panos_panorama_template_variable" "ha1-ha2_gw" {
  template_stack = panos_panorama_template_stack.azure_ha2_1.name
  name           = "$ha2-gw"
  type           = "ip-netmask"
  value          = cidrhost(azurerm_subnet.data[0].address_prefixes[0], 1)
}

/*
resource "panos_panorama_tunnel_interface" "ha1z_tun11" {
  template           = panos_panorama_template.ha1z.name
  name               = "tunnel.11"
  vsys               = "vsys1"
  static_ips         = ["169.254.12.1/30"]
  management_profile = "ping"
}
resource "panos_panorama_static_route_ipv4" "ha1z_vr1_vpn" {
  template       = panos_panorama_template.ha1z.name
  virtual_router = panos_virtual_router.ha1z_vr1.name
  type           = ""
  name           = "tunnel"
  destination    = "172.31.2.0/24"
  interface      = panos_panorama_tunnel_interface.ha1z_tun11.name
}
resource "panos_panorama_ike_gateway" "ha1z_ha2z" {
  template      = panos_panorama_template.ha1z.name
  name          = "ha2z"
  peer_ip_type  = "ip"
  peer_ip_value = one([for k, v in module.fw-ha2z_a.public_ips : v if length(regexall("internet", k)) > 0])

  interface           = "ethernet1/2"
  pre_shared_key      = "secret"
  ikev1_exchange_mode = "main"

  local_id_type  = "ipaddr"
  local_id_value = one([for k, v in module.fw-ha1z_a.public_ips : v if length(regexall("internet", k)) > 0])
  peer_id_type   = "ipaddr"
  peer_id_value  = one([for k, v in module.fw-ha2z_a.public_ips : v if length(regexall("internet", k)) > 0])

  enable_nat_traversal              = true
  nat_traversal_keep_alive          = 10
  nat_traversal_enable_udp_checksum = true

  enable_dead_peer_detection   = true
  dead_peer_detection_interval = 2
  dead_peer_detection_retry    = 5
}
resource "panos_panorama_ipsec_tunnel" "ha1z_ha2z" {
  name             = "ha2z"
  template         = panos_panorama_template.ha1z.name
  tunnel_interface = panos_panorama_tunnel_interface.ha1z_tun11.name
  anti_replay      = false
  ak_ike_gateway   = panos_panorama_ike_gateway.ha1z_ha2z.name

  enable_tunnel_monitor         = true
  tunnel_monitor_profile        = panos_panorama_monitor_profile.ha1z_fo.name
  tunnel_monitor_destination_ip = "169.254.12.2"
}

resource "panos_panorama_monitor_profile" "ha1z_fo" {
  template  = panos_panorama_template.ha1z.name
  name      = "fo-2-5"
  interval  = 2
  threshold = 5
  action    = "fail-over"
}
resource "panos_panorama_management_profile" "ha1z_ping" {
  template = panos_panorama_template.ha1z.name
  name     = "ping"
  ping     = true
}



resource "panos_security_rule_group" "ha1z_ipsec" {
  position_keyword = "bottom"
  device_group     = "azure-ha1z"
  rule {
    name                  = "ipsec ping allow"
    audit_comment         = ""
    source_zones          = ["any"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications = [
      "ipsec",
      "ping",
    ]
    services   = ["application-default"]
    categories = ["any"]
    action     = "allow"
  }
}
*/
