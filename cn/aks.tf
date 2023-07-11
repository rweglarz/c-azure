module "aks" {
  source = "../modules/aks"

  name                   = "${var.name}-k8s1"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  subnet_id              = azurerm_subnet.aks.id
  application_gateway_id = module.appgw.id
  outbound_type          = "userAssignedNATGateway"

  mgmt_cidrs = concat(
    [for r in var.mgmt_ips : "${r.cidr}"],
    [for ip in [var.panorama1_ip, var.panorama2_ip, azurerm_public_ip.ngw.ip_address]: "${ip}/32"],
  )
}

module "appgw" {
  source = "../modules/appgw"

  name                = "${var.name}-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.appgw.id
  tier                = "Standard_v2"
  use_public_ip       = true
  private_ip_address  = cidrhost(azurerm_subnet.appgw.address_prefixes[0], 10)

  virtual_hosts = {
    "dummy" = {
      priority = 11
      host_names = [
        "dummy.internal",
      ]
      ip_addresses = []
    }
  }

  managed_by_agic = true
}

output "aks_identities" {
  value = {
    aks = module.aks.identity
    appgw = module.aks.ingress_application_gateway_identity
  }
}

output "appgw" {
  value = module.appgw.public_ip_address
}
