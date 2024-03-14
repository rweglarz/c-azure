resource "panos_vm_auth_key" "this" {
  hours = 7200
  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_template_stack" "hub1" {
  name = "azure-uvwan-hub1-ts"
  templates = [
    "azure-2-if",
    "vm common"
  ]
  description = "pat:acp"

  lifecycle { create_before_destroy = true }
}

resource "panos_panorama_template_variable" "hub1" {
  for_each = {
    "$eth1_1_gw" = cidrhost(module.vnet_hub1_sec.subnets["public"].address_prefixes[0], 1)
    "$eth1_2_gw" = cidrhost(module.vnet_hub1_sec.subnets["private"].address_prefixes[0], 1)
  }
  template_stack = panos_panorama_template_stack.hub1.name
  name           = each.key
  type           = "ip-netmask"
  value          = each.value

  lifecycle { create_before_destroy = true }
}
