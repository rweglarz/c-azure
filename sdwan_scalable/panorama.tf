resource "panos_vm_auth_key" "this" {
  hours = 7200
  lifecycle {
    create_before_destroy = true
  }
}

resource "panos_panorama_template_stack" "this" {
  count = var.fw_count
  name = "azure-sdwan-scalable-ts-fw${count.index}"
  templates = [
    module.cfg_fw.template_name,
    "vm common"
  ]
  description = "pat:acp"

  lifecycle { create_before_destroy = true }
}



module "cfg_fw" {
  source = "../../ce-common/modules/pan_vm_template"

  name = "azure-sdwan-scalable-t"

  interfaces = {
    "ethernet1/1" = {
      static_ips         = ["$eth1_1_ipm"]
      zone               = "public"
      management_profile = "ping"
    }
    "ethernet1/2" = {
      static_ips         = ["$eth1_2_ipm"]
      zone               = "private"
      management_profile = "hc-azure"
    }
    "ethernet1/3" = {
      static_ips         = ["$eth1_3_ipm"]
      zone               = "private"
      management_profile = "ping"
    }
    "ethernet1/4" = {
      static_ips         = ["$eth1_4_ipm"]
      zone               = "private"
      management_profile = "ping"
    }
  }
  variables = {
    eth1_1_ipm = "192.168.1.1/32"
    eth1_2_ipm = "192.168.1.2/32"
    eth1_2_ip  = "192.168.1.2"
    eth1_3_ipm = "192.168.1.3/32"
    eth1_4_ipm = "192.168.1.4/32"
  }
  routes = {
    dg = {
      destination = "0.0.0.0/0"
      interface   = "ethernet1/1"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.public.address_prefixes[0], 1)
    }
    r10_8 = {
      destination = "10.0.0.0/8"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 1)
    }
    r172_12 = {
      destination = "172.16.0.0/12"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 1)
    }
    azure_hc = {
      destination = "168.63.129.16/32"
      interface   = "ethernet1/2"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 1)
    }
    sdwan1 = {
      destination = "${module.linux_sdwan1.private_ip_address}/32"
      interface   = "ethernet1/3"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.tosdwan1.address_prefixes[0], 1)
    }
    sdwan2 = {
      destination = "${module.linux_sdwan2.private_ip_address}/32"
      interface   = "ethernet1/4"
      type        = "ip-address"
      next_hop    = cidrhost(module.vnet_transit.subnets.tosdwan2.address_prefixes[0], 1)
    }
  }
  enable_ecmp = false
}


locals {
  fw_v = {
    for fw,v in module.fw : fw => {
        "$eth1_1_ipm" = format("%s/%s", v.private_ip_list.public[0], local.subnet_prefix_length)
        "$eth1_2_ipm" = format("%s/%s", v.private_ip_list.private[0], local.subnet_prefix_length)
        "$eth1_2_ip"  = v.private_ip_list.private[0]
        "$eth1_3_ipm" = format("%s/%s", v.private_ip_list.tosdwan1[0], local.subnet_prefix_length)
        "$eth1_4_ipm" = format("%s/%s", v.private_ip_list.tosdwan2[0], local.subnet_prefix_length)
      }
  }
  fw_v_flat = flatten([
    for fwn,fwv in local.fw_v : [
      for vn,vv in fwv: {
        name = vn
        value = vv
        ts = panos_panorama_template_stack.this[fwn].name
        fwn = "fw${fwn}-${vn}"
      }
    ]
  ])
}



resource "panos_panorama_template_variable" "this" {
  for_each = { for k,v in local.fw_v_flat: v.fwn => v}
  template_stack = each.value.ts
  name           = each.value.name
  type           = "ip-netmask"
  value          = each.value.value

  lifecycle { create_before_destroy = true }
}




resource "panos_panorama_bgp" "this" {
  template       = module.cfg_fw.template_name
  virtual_router = "vr1"
  install_route  = true

  router_id = "$eth1_2_ip"
  as_number = var.asn.fw
}


resource "panos_panorama_bgp_peer_group" "sdwan" {
  template       = module.cfg_fw.template_name
  virtual_router = "vr1"
  name           = "sdwan"
  type           = "ebgp"
  depends_on = [
    panos_panorama_bgp.this
  ]
}

resource "panos_panorama_bgp_peer" "sdwan1" {
  template                = module.cfg_fw.template_name
  name                    = "sdwan1"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.sdwan.name
  peer_as                 = var.asn.sdwan1
  local_address_interface = "ethernet1/3"
  local_address_ip        = "$eth1_3_ipm"
  peer_address_ip         = module.linux_sdwan1.private_ip_address
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

resource "panos_panorama_bgp_peer" "sdwan2" {
  template                = module.cfg_fw.template_name
  name                    = "sdwan2"
  virtual_router          = "vr1"
  bgp_peer_group          = panos_panorama_bgp_peer_group.sdwan.name
  peer_as                 = var.asn.sdwan2
  local_address_interface = "ethernet1/4"
  local_address_ip        = "$eth1_4_ipm"
  peer_address_ip         = module.linux_sdwan2.private_ip_address
  max_prefixes            = "unlimited"
  multi_hop               = 1
}

# resource "panos_panorama_bgp_redist_rule" "aws-vr1-all" {
#   template       = panos_panorama_template.aws.name
#   virtual_router = panos_virtual_router.aws-vr1.name
#   route_table    = "unicast"
#   name           = module.vpc-fw-1.vpc.cidr_block
#   set_med        = "20"
#   depends_on = [
#     panos_panorama_bgp.aws-vr1_bgp
#   ]
# }