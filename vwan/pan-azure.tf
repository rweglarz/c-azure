resource "panos_panorama_template_stack" "hub1_sec_fw" {
  name         = "azure-vwan-hub1-sec"
  default_vsys = "vsys1"
  templates = [
    "azure-1-if",
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_stack" "hub2_sec_fw" {
  name         = "azure-vwan-hub2-sec"
  default_vsys = "vsys1"
  templates = [
    "azure-1-if",
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_variable" "hub1_sec_fw_eth1_1_gw" {
  template_stack = panos_panorama_template_stack.hub1_sec_fw.name
  name           = "$eth1-1-gw"
  type           = "ip-netmask"
  value          = cidrhost(azurerm_subnet.hub1_sec_data.address_prefixes[0], 1)
}

resource "panos_panorama_template_variable" "hub2_sec_fw_eth1_1_gw" {
  template_stack = panos_panorama_template_stack.hub2_sec_fw.name
  name           = "$eth1-1-gw"
  type           = "ip-netmask"
  value          = cidrhost(azurerm_subnet.hub2_sec_data.address_prefixes[0], 1)
}
