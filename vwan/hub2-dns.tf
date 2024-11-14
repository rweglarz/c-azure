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
    "dnso" = {
      idx                       = 1
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
  tags = {
    role = "dns"
    type = "dnspei"
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "hub2" {
  name                      = "${local.dname}-hub2"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  virtual_network_id        = module.hub2_dns.id
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "hub2" {
  name                    = "${local.dname}-hub2-out"
  private_dns_resolver_id = azurerm_private_dns_resolver.hub2.id
  location                = azurerm_resource_group.rg1.location
  subnet_id               = module.hub2_dns.subnets.dnso.id
  tags = {
    role = "dns"
    type = "dnspeo"
  }
}


resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub2" {
  name                = "${local.dname}-hub2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.hub2.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "hub2-r1" {
  name                      = "dns1"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  domain_name               = "onprem1.test."
  enabled                   = true
  target_dns_servers {
    ip_address = "172.16.5.5"
    port       = 53 # cannot be different
  }
}
resource "azurerm_private_dns_resolver_forwarding_rule" "hub2-r2" {
  name                      = "dns2"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  domain_name               = "onprem2.test."
  enabled                   = true
  target_dns_servers {
    ip_address = "172.16.5.5"
    port       = 53
  }
}
