module "cfg_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "fw-common-t"

  interfaces = {
    "ethernet1/1" = {
      zone               = "internet"
      management_profile = "hc-azure"
      enable_dhcp        = true
    }
    "ethernet1/2" = {
      zone               = "internal"
      management_profile = "hc-azure"
      enable_dhcp        = true
    }
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.fw["eth1_1_gw"]
    }
    i10 = {
      destination = "10.0.0.0/8"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.private_ips.fw["eth1_2_gw"]
    }
    i172 = {
      destination = "172.16.0.0/12"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.private_ips.fw["eth1_2_gw"]
    }
    i192 = {
      destination = "192.168.0.0/16"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.private_ips.fw["eth1_2_gw"]
    }
    hc-1 = {
      destination = "168.63.129.16/32"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = local.private_ips.fw["eth1_1_gw"]
    }
    hc-2 = {
      destination = "168.63.129.16/32"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = local.private_ips.fw["eth1_2_gw"]
    }
  }
  enable_ecmp = true
}
