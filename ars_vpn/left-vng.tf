resource "azurerm_public_ip" "vng_left" {
  name                = "${var.name}-left-vng"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "left" {
  name                = "${var.name}-left"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type     = "Vpn"
  vpn_type = "PolicyBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.vng_left.id
    subnet_id                     = module.vnet_left_hub.subnets["GatewaySubnet"].id
  }
}

resource "azurerm_local_network_gateway" "right_seen_by_left" {
  name                = "${var.name}-right-seen-by-left"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  gateway_address = azurerm_public_ip.vng_right.ip_address
  address_space = [
    module.vnet_right_hub.vnet.address_space[0],
  ]
}

resource "azurerm_virtual_network_gateway_connection" "left_right_1" {
  name                = "${var.name}-left-right-1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.left.id
  local_network_gateway_id   = azurerm_local_network_gateway.right_seen_by_left.id

  shared_key = var.psk
}
