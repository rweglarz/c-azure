resource "panos_panorama_template" "azure_vwan_hub2_sdwan" {
  name = "azure-vwan-hub2-sdwan"
}

resource "panos_panorama_template_stack" "azure_vwan_hub2_sdwan_fw1" {
  name         = "azure-vwan-hub2-sdwan-fw1"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_hub2_sdwan.name,
    "sdwan",
    "vm common",
  ]
  description = "pat:acp"
}

resource "panos_panorama_template_stack" "azure_vwan_hub2_sdwan_fw2" {
  name         = "azure-vwan-hub2-sdwan-fw2"
  default_vsys = "vsys1"
  templates = [
    panos_panorama_template.azure_vwan_hub2_sdwan.name,
    "sdwan",
    "vm common",
  ]
  description = "pat:acp"
}



resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw1-eth1_1_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
  name           = "$eth1_1_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.hub2_sdwan_fw1["eth1_1_ip"], local.subnet_prefix_length)
}

resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw1-eth1_1_gw" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
  name           = "$eth1_1_gw"
  type           = "ip-netmask"
  value          = local.hub2_sdwan_fw1["eth1_1_gw"]
}

resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw1-eth1_2_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw1.name
  name           = "$eth1_2_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.hub2_sdwan_fw1["eth1_2_ip"], local.subnet_prefix_length)
}


resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw2-eth1_1_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
  name           = "$eth1_1_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.hub2_sdwan_fw2["eth1_1_ip"], local.subnet_prefix_length)
}

resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw2-eth1_1_gw" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
  name           = "$eth1_1_gw"
  type           = "ip-netmask"
  value          = local.hub2_sdwan_fw2["eth1_1_gw"]
}

resource "panos_panorama_template_variable" "azure_vwan_hub2_sdwan_fw2-eth1_2_ip" {
  template_stack = panos_panorama_template_stack.azure_vwan_hub2_sdwan_fw2.name
  name           = "$eth1_2_ip"
  type           = "ip-netmask"
  value          = format("%s/%s", local.hub2_sdwan_fw2["eth1_2_ip"], local.subnet_prefix_length)
}

