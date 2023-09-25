module "aks1" {
  source = "../modules/aks"

  name                   = "${var.name}-k8s1"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  subnet_id              = module.vnet_aks.subnets.aks1.id
  application_gateway_id = module.appgw1.id
  outbound_type          = "userAssignedNATGateway"

  mgmt_cidrs = concat(
    [for r in var.mgmt_ips : "${r.cidr}"],
    [for ip in [var.panorama1_ip, var.panorama2_ip, azurerm_public_ip.natgw.ip_address]: "${ip}/32"],
  )
}


module "appgw1" {
  source = "../modules/appgw"

  name                = "${var.name}-appgw1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_aks.subnets.appgw1.id
  tier                = "Standard_v2"
  use_public_ip       = true
  private_ip_address  = cidrhost(module.vnet_aks.subnets.appgw1.address_prefixes[0], 10)

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


output "aks1_identities" {
  value = {
    aks = module.aks1.identity
    appgw = module.aks1.ingress_application_gateway_identity
  }
}

output "appgw1" {
  value = module.appgw1.public_ip_address
}
