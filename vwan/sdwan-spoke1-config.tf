resource "panos_panorama_template" "azure_vwan_sdwan_spoke1_fw" {
  name = "azure-vwan-sdwan-spoke1"
}

resource "panos_panorama_template_stack" "azure_vwan_sdwan_spoke1_fw" {
  name         = "azure-vwan-sdwan-spoke1-fw"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_sdwan_spoke1_fw.name,
    "sdwan",
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
