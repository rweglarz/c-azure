#region variables
resource "scm_variable" "private_ipm" {
  folder = var.scm_folder
  name   = "$fw-private-ipm"

  type  = "ip-netmask"
  value = "${var.private_ips.ngfw}/${var.subnet_prefix_length}"
}

resource "scm_variable" "private_ip" {
  folder = var.scm_folder
  name   = "$fw-private-ip"

  type  = "ip-netmask"
  value = var.private_ips.ngfw
}

resource "scm_variable" "fw_asn" {
  folder = var.scm_folder

  name  = "$fw-asn"
  type  = "as-number"
  value = var.asn.ngfw
}

resource "scm_variable" "ars_asn" {
  folder = var.scm_folder

  name  = "$ars-asn"
  type  = "as-number"
  value = var.asn.ars
}
#endregion


#region network
resource "scm_zone" "private" {
  name   = "private"
  folder = var.scm_folder

  network = {
    layer3 = [
      scm_ethernet_interface.eth1_1.name
    ]
  }
}

resource "scm_ethernet_interface" "eth1_1" {
  folder        = var.scm_folder
  name          = "$ethernet1_1"
  default_value = "ethernet1/1"

  layer3 = {
    ip = [
      {
        name = "${var.private_ips.ngfw}/${var.subnet_prefix_length}"
      }
    ]
  }
}

resource "scm_logical_router" "default" {
  folder = var.scm_folder
  name   = "lr-ars"

  routing_stack = "advanced"

  vrf = [{
    name = "default"
    interface = [
      scm_ethernet_interface.eth1_1.name,
    ]

    routing_table = {
      ip = {
        static_route = [
          {
            name        = "default-route"
            destination = "0.0.0.0/0"
            preference  = 10
            nexthop = {
              ip_address = var.private_ips.transit_data_gw
            }
          },
          {
            name        = "ra-98"
            destination = "172.16.98.0/24"
            preference  = 10
            nexthop = { discard = {} }
          },
          {
            name        = "ra-99"
            destination = "172.16.99.255/32"
            preference  = 10
            nexthop = { discard = {} }
          },
        ]
      }
    }

    bgp = {
      router_id     = scm_variable.private_ip.name
      local_as      = scm_variable.fw_asn.name
      enable        = true
      install_route = true

      redistribution_profile = {
        ipv4 = {
          unicast = scm_bgp_redistribution_profile.static.name
        }
      }
      aggregate_routes = [
        {
          name         = "ag-4"
          enable       = true
          as_set       = false
          same_med     = false
          summary_only = true
          type = {
            ipv4 = {
              summary_prefix = "172.16.4.0/24"
            }
          }
        },
        {
          name         = "ag-5"
          enable       = true
          as_set       = false
          same_med     = false
          summary_only = false
          type = {
            ipv4 = {
              summary_prefix = "172.16.5.0/24"
            }
          }
        },
        {
          name         = "ag-99"
          enable       = true
          as_set       = false
          same_med     = false
          summary_only = true
          type = {
            ipv4 = {
              summary_prefix = "172.16.99.0/24"
            }
          }
        }
      ]
      peer_group = [
        {
          name   = "ars"
          enable = true
          address_family = {
            ipv4 = "default"
          }
          connection_options = {
            multihop = 1
          }
          type = {
            ebgp = {}
          }
          filtering_profile = {
            ipv4 = scm_bgp_filtering_profile.ars.name
          }
          peer = [
            {
              name    = "ars_i0"
              enable  = true
              peer_as = scm_variable.ars_asn.name
              peer_address = {
                ip = var.private_ips.ars1
              }
              local_address = {
                interface = scm_ethernet_interface.eth1_1.name
              }
              # connection_options = {
              #   multihop = "inherit"
              # }
              # inherit = {
              #   yes = {}
              # }
            },
            {
              name    = "ars_i1"
              enable  = true
              peer_as = scm_variable.ars_asn.name
              peer_address = {
                ip = var.private_ips.ars2
              }
              local_address = {
                interface = scm_ethernet_interface.eth1_1.name
              }
              # connection_options = {
              #   multihop = "inherit"
              # }
              # inherit = {
              #   yes = {}
              # }
            }
          ]
        },
        {
          name   = "third-party"
          enable = true
          address_family = {
            ipv4 = "default"
          }
          connection_options = {
            multihop = 1
          }
          type = {
            ebgp = {}
          }
          filtering_profile = {
            ipv4 = scm_bgp_filtering_profile.third_party.name
          }
          peer = [
            {
              name    = "tp"
              enable  = true
              peer_as = var.asn.third_party
              peer_address = {
                ip = var.private_ips.third_party
              }
              local_address = {
                interface = scm_ethernet_interface.eth1_1.name
              }
              # connection_options = {
              #   multihop = "inherit"
              # }
              # inherit = {
              #   yes = {}
              # }
            },
          ]
        }
      ]
    }
  }]
  # depends_on = [ scm_ethernet_interface.eth1_1 ]
}

resource "scm_bgp_redistribution_profile" "static" {
  folder = var.scm_folder
  name = "rp-static"

  ipv4 = {
    unicast = {
      static = {
        enable = true
        metric = 10
      }
    }
  }
}
#endregion


#region bgp common
locals {
  prefix-lists = {
    pl-third-party-outbound = {
      1  = "172.16.1.0/24"
      3  = "172.16.3.0/24"
      4  = "172.16.4.0/24"
      5  = "172.16.5.0/24"
      98 = "172.16.98.0/24"
      99 = "172.16.99.0/24"
    }
    pl-third-party-inbound = {
      1 = "10.233.1.0/24"
      2 = "10.233.2.0/24"
      3 = "10.233.3.0/24"
    }
    pl-ars-outbound-12 = {
      1 = "10.233.1.0/24"
      2 = "10.233.2.0/24"
    }
    pl-ars-outbound-3 = {
      3 = "10.233.3.0/24"
    }
  }
}
#endregion



#region bgp third party
resource "scm_route_prefix_list" "this" {
  for_each = local.prefix-lists
  folder   = var.scm_folder
  name     = each.key

  type = {
    ipv4 = {
      ipv4_entry = [
        for k,v in each.value: {
          name   = k
          action = "permit"
          prefix = {
            entry = {
              network = v
            }
          }
        }
      ]
    }
  }
}

resource "scm_bgp_filtering_profile" "third_party" {
  folder = var.scm_folder
  name = "fp-third-party"

  ipv4 = {
    unicast = {
      inbound_network_filters = {
        prefix_list = scm_route_prefix_list.this["pl-third-party-inbound"].name
      }
      outbound_network_filters = {
        prefix_list = scm_route_prefix_list.this["pl-third-party-outbound"].name
      }
    }
  }
}
#endregion



#region bgp ars
resource "scm_bgp_route_map" "ars_outbound" {
  folder      = var.scm_folder
  name        = "rm-ars-outbound"

  route_map = [
    {
      name   = 1
      action = "permit"
      match  = {
        ipv4 = {
          address = {
            prefix_list = scm_route_prefix_list.this["pl-ars-outbound-12"].name
          }
        }
      }
      set = { 
        aspath_prepend = [
          var.asn.ngfw,
          var.asn.ngfw,
        ]
      }
    },
    {
      name   = 2
      action = "permit"
      match  = {
        ipv4 = {
          address = {
            prefix_list = scm_route_prefix_list.this["pl-ars-outbound-3"].name
          }
        }
      }
      set = { 
        aspath_prepend = [
          var.asn.ngfw,
          var.asn.ngfw,
          var.asn.ngfw,
        ]
      }
    },
  ]
}

resource "scm_bgp_filtering_profile" "ars" {
  folder = var.scm_folder
  name = "fp-ars"

  ipv4 = {
    unicast = {
      route_maps = {
        outbound = scm_bgp_route_map.ars_outbound.name
      }
    }
  }
}

#endregion
