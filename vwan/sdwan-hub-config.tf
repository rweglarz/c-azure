resource "panos_panorama_template" "azure_vwan_hub2_sdwan" {
  name = "azure-vwan-hub2-sdwan"
}

resource "panos_panorama_template" "azure_vwan_hub4_sdwan" {
  name = "azure-vwan-hub4-sdwan"
}

resource "panos_panorama_template_stack" "azure_vwan_hub2_sdwan_fw" {
  name         = "azure-vwan-hub2-sdwan-fw"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_hub2_sdwan.name,
    "sdwan-1isp",
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_stack" "azure_vwan_hub4_sdwan_fw" {
  name         = "azure-vwan-hub4-sdwan-fw"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_hub4_sdwan.name,
    "sdwan-1isp",
    "vm common",
  ]
  description = "pat:acp"
}



resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw-eth1_1_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  name           = "$eth1_1_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.hub2_sdwan_fw["eth1_1_ip"], local.subnet_prefix_length)
}

resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw-eth1_1_gw" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  name           = "$eth1_1_gw"
  type           = "ip-netmask"
  value          = local.hub2_sdwan_fw["eth1_1_gw"]
}

resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw-eth1_2_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  name           = "$eth1_2_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.hub2_sdwan_fw["eth1_2_ip"], local.subnet_prefix_length)
}

resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw-lo1_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  name           = "$lo1_ip"
  type           = "ip-netmask"
  value          = format("%s/32", panos_panorama_bgp.azure_vwan_hub2_sdwan_fw.router_id)
}


resource "panos_panorama_template_variable" "azure_vwan_hub4_sdwan_fw-eth1_1_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  name           = "$eth1_1_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.hub4_sdwan_fw["eth1_1_ip"], local.subnet_prefix_length)
}


resource "panos_panorama_template_variable" "azure_vwan_hub4_sdwan_fw-eth1_1_gw" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  name           = "$eth1_1_gw"
  type           = "ip-netmask"
  value          = local.hub4_sdwan_fw["eth1_1_gw"]
}

resource "panos_panorama_template_variable" "azure_vwan_hub4_sdwan_fw-eth1_2_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  name           = "$eth1_2_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.hub4_sdwan_fw["eth1_2_ip"], local.subnet_prefix_length)
}

resource "panos_panorama_template_variable" "azure_vwan_hub4_sdwan_fw-lo1_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  name           = "$lo1_ip"
  type           = "ip-netmask"
  value          = format("%s/32", panos_panorama_bgp.azure_vwan_hub4_sdwan_fw.router_id)
}



resource "panos_panorama_static_route_ipv4" "azure_vwan_hub2_sdwan_fw-dg" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  virtual_router = "vr1"
  name           = "dg"
  destination    = "0.0.0.0/0"
  next_hop       = local.hub2_sdwan_fw["eth1_1_gw"]
  interface      = "ethernet1/1"
}

resource "panos_panorama_static_route_ipv4" "azure_vwan_hub4_sdwan_fw-dg" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  virtual_router = "vr1"
  name           = "dg"
  destination    = "0.0.0.0/0"
  next_hop       = local.hub4_sdwan_fw["eth1_1_gw"]
  interface      = "ethernet1/1"
}


resource "panos_panorama_static_route_ipv4" "azure_vwan_hub2_sdwan_fw-hub2" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  virtual_router = "vr1"
  name           = "hub2"
  destination    = azurerm_virtual_hub.hub2.address_prefix
  next_hop       = local.hub2_sdwan_fw["eth1_2_gw"]
  interface      = "ethernet1/2"
}

resource "panos_panorama_static_route_ipv4" "azure_vwan_hub4_sdwan_fw-hub2" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  virtual_router = "vr1"
  name           = "hub4"
  destination    = azurerm_virtual_hub.hub2.address_prefix
  next_hop       = local.hub4_sdwan_fw["eth1_2_gw"]
  interface      = "ethernet1/2"
}


resource "panos_panorama_bgp" "azure_vwan_hub2_sdwan_fw" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["hub2_sdwan_fw"]
  as_number = var.asn["hub2_sdwan_fw"]
}

resource "panos_panorama_bgp" "azure_vwan_hub4_sdwan_fw" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  virtual_router = "vr1"
  install_route  = true

  router_id = var.router_ids["hub4_sdwan_fw"]
  as_number = var.asn["hub4_sdwan_fw"]
}


resource "panos_panorama_bgp_peer_group" "azure_vwan_hub2_sdwan_fw" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  virtual_router = "vr1"
  name           = "azure"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.azure_vwan_hub2_sdwan_fw
  ]
}

resource "panos_panorama_bgp_peer_group" "azure_vwan_hub4_sdwan_fw" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  virtual_router = "vr1"
  name           = "azure"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.azure_vwan_hub4_sdwan_fw
  ]
}


resource "panos_panorama_bgp_peer" "azure_vwan_hub2_sdwan_fw-hub2_i1" {
  template_stack          = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  name                    = "hub2_i1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.azure_vwan_hub2_sdwan_fw.name
  peer_as                 = azurerm_virtual_hub.hub2.virtual_router_asn
  local_address_interface = "ethernet1/2"
  local_address_ip        = "$eth1_2_ip"
  peer_address_ip         = azurerm_virtual_hub.hub2.virtual_router_ips[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "azure_vwan_hub2_sdwan_fw-hub2_i2" {
  template_stack          = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw.name
  name                    = "hub2_i2"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.azure_vwan_hub2_sdwan_fw.name
  peer_as                 = azurerm_virtual_hub.hub2.virtual_router_asn
  local_address_interface = "ethernet1/2"
  local_address_ip        = "$eth1_2_ip"
  peer_address_ip         = azurerm_virtual_hub.hub2.virtual_router_ips[1]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "azure_vwan_hub4_sdwan_fw-hub2_i1" {
  template_stack          = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  name                    = "hub2_i1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.azure_vwan_hub4_sdwan_fw.name
  peer_as                 = azurerm_virtual_hub.hub2.virtual_router_asn
  local_address_interface = "ethernet1/2"
  local_address_ip        = "$eth1_2_ip"
  peer_address_ip         = azurerm_virtual_hub.hub2.virtual_router_ips[0]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "azure_vwan_hub4_sdwan_fw-hub2_i2" {
  template_stack          = panos_panorama_template_stack.azure_vwan_hub4_sdwan_fw.name
  name                    = "hub2_i2"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.azure_vwan_hub4_sdwan_fw.name
  peer_as                 = azurerm_virtual_hub.hub2.virtual_router_asn
  local_address_interface = "ethernet1/2"
  local_address_ip        = "$eth1_2_ip"
  peer_address_ip         = azurerm_virtual_hub.hub2.virtual_router_ips[1]
  max_prefixes            = "unlimited"
  multi_hop               = 1
}


