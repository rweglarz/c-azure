resource "azurerm_private_dns_zone" "this" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = {
     sec = azurerm_virtual_network.sec.id
  }
  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value
}

resource "azurerm_private_dns_a_record" "this" {
  for_each = {
    app01-prod  = module.app01_prod_srv[0].private_ip_address,
    app01-dev   = module.app01_dev_srv[0].private_ip_address,
    app02       = module.app02_srv[0].private_ip_address,
  }
  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
  zone_name           = azurerm_private_dns_zone.this.name
  ttl                 = 120
  records = [
    each.value
  ]
}



resource "azurerm_private_dns_resolver" "sec" {
  name                = "${local.dname}-sec"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  virtual_network_id  = azurerm_virtual_network.sec.id
}


resource "azurerm_private_dns_resolver_inbound_endpoint" "sec" {
  name                    = "${local.dname}-s"
  private_dns_resolver_id = azurerm_private_dns_resolver.sec.id
  location                = azurerm_resource_group.rg.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.dns.id
  }
  tags = {
    role = "dns"
    type = "dnspei"
  }
}


output "dns_endpoint" {
  value = azurerm_private_dns_resolver_inbound_endpoint.sec.ip_configurations[0].private_ip_address
}
