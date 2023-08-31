resource "panos_panorama_template" "azure_vwan_sdwan_spoke1_fw" {
  name = "azure-vwan-sdwan-spoke1"
}

resource "panos_panorama_template_stack" "azure_vwan_sdwan_spoke1_fw" {
  name         = "azure-vwan-sdwan-spoke1-fw"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_sdwan_spoke1_fw.name,
    "sdwan-2isp",
    "vm common",
  ]
  description = "pat:acp"
}



resource "panos_panorama_template_variable" "azure_vwan_sdwan_spoke1_fw-eth1_1_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
  name           = "$eth1_1_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.sdwan_spoke1_fw["eth1_1_ip"], local.subnet_prefix_length)
}

resource "panos_panorama_template_variable" "azure_vwan_sdwan_spoke1_fw-eth1_1_gw" {
  template_stack = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
  name           = "$eth1_1_gw"
  type           = "ip-netmask"
  value          = local.sdwan_spoke1_fw["eth1_1_gw"]
}

resource "panos_panorama_template_variable" "azure_vwan_sdwan_spoke1_fw-eth1_2_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
  name           = "$eth1_2_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.sdwan_spoke1_fw["eth1_2_ip"], local.subnet_prefix_length)
}

resource "panos_panorama_template_variable" "azure_vwan_sdwan_spoke1_fw-eth1_2_gw" {
  template_stack = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
  name           = "$eth1_2_gw"
  type           = "ip-netmask"
  value          = local.sdwan_spoke1_fw["eth1_2_gw"]
}

resource "panos_panorama_template_variable" "azure_vwan_sdwan_spoke1_fw-eth1_3_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
  name           = "$eth1_3_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.sdwan_spoke1_fw["eth1_3_ip"], local.subnet_prefix_length)
}


resource "panos_panorama_template_variable" "azure_vwan_sdwan_spoke1_fw-lo1_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
  name           = "$lo1_ip"
  type           = "ip-netmask"
  value          = format("%s/32", panos_panorama_bgp.azure_vwan_sdwan_spoke1_fw.router_id)
}

resource "panos_panorama_bgp" "azure_vwan_sdwan_spoke1_fw" {
  template_stack = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
  virtual_router = "vr1"
  install_route  = true
  always_compare_med = true

  router_id = var.router_ids["sdwan_spoke1_fw"]
  as_number = var.asn["sdwan_spoke1_fw"]
}

resource "panos_panorama_static_route_ipv4" "azure_vwan_sdwan_spoke1_fw-prv" {
  template_stack = panos_panorama_template_stack.azure_vwan_sdwan_spoke1_fw.name
  virtual_router = "vr1"
  name           = "prv"
  destination    = module.sdwan_spoke1.vnet.address_space[0]
  next_hop       = local.sdwan_spoke1_fw["eth1_3_gw"]
  interface      = "ethernet1/3"
}
