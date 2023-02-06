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
    public_ip_address_id = azurerm_public_ip.vng_left.id
    subnet_id            = module.vnet_left_hub.subnets["GatewaySubnet"].id
  }
}

resource "azurerm_local_network_gateway" "right_seen_by_left" {
  name                = "${var.name}-right-seen-by-left"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  gateway_address = azurerm_public_ip.vng_right.ip_address
  address_space = [
    module.vnet_right_hub.vnet.address_space[0],
    module.vnet_right_srv_1.vnet.address_space[0],
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

resource "azurerm_route_table" "left_vng" {
  name                = "${var.name}-left-vng"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_route" "left_vng-peers_via_fw" {
  for_each = {
    srv1 = module.vnet_left_srv_1.vnet.address_space[0]
  }
  name                   = each.key
  resource_group_name    = azurerm_resource_group.this.name
  route_table_name       = azurerm_route_table.left_vng.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.private_ips.left_hub_fw["eth1_1_ip"]
}

resource "azurerm_subnet_route_table_association" "left_vng" {
  subnet_id      = module.vnet_left_hub.subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.left_vng.id
}
