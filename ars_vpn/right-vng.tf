resource "azurerm_public_ip" "vng_right" {
  name                = "${var.name}-right-vng"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "right" {
  name                = "${var.name}-right"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type     = "Vpn"
  vpn_type = "PolicyBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.vng_right.id
    subnet_id                     = module.vnet_right_hub.subnets["GatewaySubnet"].id
  }
}

resource "azurerm_local_network_gateway" "left_seen_by_right" {
  name                = "${var.name}-left-seen-by-right"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  gateway_address = azurerm_public_ip.vng_left.ip_address
  address_space = [
    module.vnet_left_hub.vnet.address_space[0],
    module.vnet_left_srv_1.vnet.address_space[0],
    module.vnet_left_srv_2.vnet.address_space[0],
  ]
}

resource "azurerm_virtual_network_gateway_connection" "right_left_1" {
  name                = "${var.name}-right-left-1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.right.id
  local_network_gateway_id   = azurerm_local_network_gateway.left_seen_by_right.id

  shared_key = var.psk
}
