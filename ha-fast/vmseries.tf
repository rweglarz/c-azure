locals {
  private_ips = {
    fw0 = {
      mgmt      = cidrhost(module.vnet_transit.subnets.mgmt.address_prefixes[0], 6),
      private   = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 6),
      public    = cidrhost(module.vnet_transit.subnets.public.address_prefixes[0], 6),
      ha2       = cidrhost(module.vnet_transit.subnets.ha2.address_prefixes[0], 6),
      ha2-gw    = cidrhost(module.vnet_transit.subnets.ha2.address_prefixes[0], 1),
      mgmt-peer = cidrhost(module.vnet_transit.subnets.mgmt.address_prefixes[0], 7),
    }
    fw1 = {
      mgmt      = cidrhost(module.vnet_transit.subnets.mgmt.address_prefixes[0], 7),
      private   = cidrhost(module.vnet_transit.subnets.private.address_prefixes[0], 7),
      public    = cidrhost(module.vnet_transit.subnets.public.address_prefixes[0], 7),
      ha2       = cidrhost(module.vnet_transit.subnets.ha2.address_prefixes[0], 7),
      ha2-gw    = cidrhost(module.vnet_transit.subnets.ha2.address_prefixes[0], 1),
      mgmt-peer = cidrhost(module.vnet_transit.subnets.mgmt.address_prefixes[0], 6),
    }
  }
}


module "fw" {
  for_each = var.vmseries
  source   = "github.com/PaloAltoNetworks/terraform-azurerm-swfw-modules//modules/vmseries?ref=v3.5.1"

  name                = "${var.name}-${each.key}"
  resource_group_name = azurerm_resource_group.this.name
  region              = azurerm_resource_group.this.location

  authentication = {
    username            = var.username
    password            = var.password
    disable_password_authentication = false
  }
  image = {
    version         = var.fw_version
    sku             = "byol"
  }
  virtual_machine = {
    vm_size           = try(each.value.vm_size, "Standard_D3_v2")
    zone              = each.value.zone
    disk_name         = "${var.name}-${each.key}"
    bootstrap_options = join(";", 
      [for k, v in merge (
        var.bootstrap_options,
        {
          vm-auth-key = panos_vm_auth_key.this.auth_key,
          tplname = panos_panorama_template_stack.fw[each.key].name,
        },
      ) : "${k}=${v}"],
    )
  }
  interfaces = [
    {
      name               = "${var.name}-${each.key}-mgmt"
      subnet_id          = module.vnet_transit.subnets.mgmt.id
      ip_configurations = {
        primary = {
          private_ip_address = local.private_ips[each.key].mgmt
          public_ip_name     = "${var.name}-${each.key}-mgmt"
          create_public_ip   = true
        }
      }
    },
    {
      name                      = "${var.name}-${each.key}-public"
      subnet_id                 = module.vnet_transit.subnets.public.id
      lb_backend_pool_id        = module.slb_fw_ext.backend_pool_id
      attach_to_lb_backend_pool = true
      ip_configurations = {
        primary = {
          private_ip_address   = local.private_ips[each.key].public
          create_public_ip     = false
        }
      }
    },
    {
      name                      = "${var.name}-${each.key}-private"
      subnet_id                 = module.vnet_transit.subnets.private.id
      lb_backend_pool_id        = module.slb_fw_int.backend_pool_id
      attach_to_lb_backend_pool = true
      ip_configurations = {
        primary = {
          private_ip_address   = local.private_ips[each.key].private
        }
      }
    },
    {
      name                 = "${var.name}-${each.key}-ha2"
      subnet_id            = module.vnet_transit.subnets.ha2.id
      ip_configurations = {
        primary = {
          private_ip_address   = local.private_ips[each.key].ha2
        }
      }
    },
  ]

}
