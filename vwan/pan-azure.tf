resource "panos_panorama_template_stack" "hub1_sec_fw" {
  name         = "azure-vwan-hub1-sec"
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
  value          = cidrhost(module.hub1_sec.subnets.data.address_prefixes[0], 1)
}

