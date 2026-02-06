#region variables
resource "scm_variable" "private_ipm" {
  folder      = var.scm_folder
  name        = "$fw-private-ipm"

  type        = "ip-netmask"
  value       = "${var.private_ips.ngfw}/${var.subnet_prefix_length}"
}

resource "scm_variable" "private_ip" {
  folder      = var.scm_folder
  name        = "$fw-private-ip"

  type        = "ip-netmask"
  value       = var.private_ips.ngfw
}

resource "scm_variable" "fw_asn" {
  folder      = var.scm_folder

  name        = "$fw-asn"
  type        = "as-number"
  value       = var.asn.ngfw
}

resource "scm_variable" "ars_asn" {
  folder      = var.scm_folder

  name        = "$ars-asn"
  type        = "as-number"
  value       = var.asn.ars
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
          }
        ]
      }
    }

    bgp = {
      router_id = scm_variable.private_ip.name
      local_as  = scm_variable.fw_asn.name
      enable    = true
      install_route = true

      peer_group = [
          {
            name = "ars"
            enable = true
            address_family = {
              ipv4 = "default"
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
              }
            ]
          }
      ]
    } 
  }]
  # depends_on = [ scm_ethernet_interface.eth1_1 ]
}
#endregion
