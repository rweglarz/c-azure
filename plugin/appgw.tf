module "appgw_ext" {
  source = "../modules/appgw"

  name                = "${var.name}-appgw-ext"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.appgw_ext_s1.id
  tier                = "Standard_v2"
  use_public_ip       = true

  virtual_hosts = {
    "appgw1" = {
      priority = 11
      host_names = [
        "appgw1.internal",
      ]
      ip_addresses = [
        cidrhost(azurerm_subnet.appgw_int_s1.address_prefixes[0], 5)
      ]
    }
    "appgw2" = {
      priority = 12
      host_names = [
        "appgw2.internal",
      ]
      ip_addresses = [
        cidrhost(azurerm_subnet.appgw_int_s2.address_prefixes[0], 5)
      ]
    }
    "h1" = {
      priority = 21
      host_names = [
        "host1.internal",
      ]
      ip_addresses = [
        cidrhost(azurerm_subnet.w1_s1.address_prefixes[0], 5)
      ]
    }
  }

  private_ip_address = cidrhost(azurerm_subnet.appgw_ext_s1.address_prefixes[0], 5)
}

module "appgw_int_1" {
  source = "../modules/appgw"

  name                = "${var.name}-appgw-int-v1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.appgw_int_s1.id
  tier                = "Standard"
  use_public_ip       = false

  virtual_hosts = {
    "all" = {
      priority   = 11
      host_names = [] #not used on non v2
      ip_addresses = [
        cidrhost(azurerm_subnet.w1_s1.address_prefixes[0], 5)
      ]
    }
  }

  private_ip_address = cidrhost(azurerm_subnet.appgw_int_s1.address_prefixes[0], 5)
}

module "appgw_int_2" {
  source = "../modules/appgw"

  name                = "${var.name}-appgw-int-v2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.appgw_int_s2.id
  tier                = "Standard_v2"
  use_public_ip       = false

  virtual_hosts = {
    "all" = {
      priority = 11
      host_names = []
      ip_addresses = [
        cidrhost(azurerm_subnet.w1_s1.address_prefixes[0], 5)
      ]
    }
  }

  private_ip_address = cidrhost(azurerm_subnet.appgw_int_s2.address_prefixes[0], 5)
}
