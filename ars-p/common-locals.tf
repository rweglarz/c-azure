locals {
  subnet_prefix_length = 27

  template_prefix = "azure-ars-s"

  app_vnets = {
    app1 = {
      idx = 1
    }
    app2 = {
      idx = 2
    }
  }

  transit_fws = {
    fw1 = {
      mgmt_ip   = cidrhost(module.vnet_transit.subnets["mgmt"].address_prefixes[0], 11)
      eth1_1_ip = cidrhost(module.vnet_transit.subnets["public"].address_prefixes[0], 11)
      eth1_2_ip = cidrhost(module.vnet_transit.subnets["private"].address_prefixes[0], 11)
    }
    fw2 = {
      mgmt_ip   = cidrhost(module.vnet_transit.subnets["mgmt"].address_prefixes[0], 12)
      eth1_1_ip = cidrhost(module.vnet_transit.subnets["public"].address_prefixes[0], 12)
      eth1_2_ip = cidrhost(module.vnet_transit.subnets["private"].address_prefixes[0], 12)
    }
  }
  onprem_fw = {
    mgmt_ip   = cidrhost(module.vnet_onprem.subnets["mgmt"].address_prefixes[0], 11)
    eth1_1_ip = cidrhost(module.vnet_onprem.subnets["isp1"].address_prefixes[0], 11)
    eth1_2_ip = cidrhost(module.vnet_onprem.subnets["isp2"].address_prefixes[0], 11)
    eth1_3_ip = cidrhost(module.vnet_onprem.subnets["private"].address_prefixes[0], 11)
  }
  transit_ilb = cidrhost(module.vnet_transit.subnets["private"].address_prefixes[0], 5)

  peering_addresses = {
    vng = {
      c1 = [
        "169.254.21.1",
        "169.254.21.2"
      ]
      c2 = [
        "169.254.21.3",
        "169.254.21.4"
      ]
    }
    onprem_fw = [
      "169.254.22.1",
      "169.254.22.2"
    ]
  }
}
