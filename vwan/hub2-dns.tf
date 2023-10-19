module "hub2_dns" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  name          = "${local.dname}-hub2-dns"
  address_space = [local.vnet_cidr.hub2_dns]

  subnets = {
    "dns" = {
      idx                       = 0
      network_security_group_id = module.basic_rg1.sg_id.wide-open
      associate_nsg             = true
      delegations = toset([
        "dnsResolvers",
      ])
    },
  }
}

resource "azurerm_private_dns_resolver" "hub2" {
  name                = "${local.dname}-hub2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  virtual_network_id  = module.hub2_dns.id
}


resource "azurerm_private_dns_resolver_inbound_endpoint" "hub2" {
  name                    = "${local.dname}-hub2"
  private_dns_resolver_id = azurerm_private_dns_resolver.hub2.id
  location                = azurerm_resource_group.rg1.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = module.hub2_dns.subnets.dns.id
  }
}

