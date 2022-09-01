resource "azurerm_virtual_network" "srv" {
  name                = "${var.name}-srv"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.srv_vpc_cidr]
}

resource "azurerm_subnet" "s1" {
  name                 = "${var.name}-srv-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.srv.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.srv.address_space[0], 8, 0)]
}
resource "azurerm_subnet" "s2" {
  name                 = "${var.name}-srv-s2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.srv.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.srv.address_space[0], 8, 1)]
}

resource "azurerm_virtual_network_peering" "srv-fw" {
  name                      = "${var.name}-srv-fw"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.srv.name
  remote_virtual_network_id = azurerm_virtual_network.sec.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "fw-srv" {
  name                      = "${var.name}-fw-srv"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sec.name
  remote_virtual_network_id = azurerm_virtual_network.srv.id
}


resource "azurerm_route_table" "srv" {
  name                = "${var.name}-srv"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route" "srv-dg-fw" {
  name                   = "dg_fw"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.srv.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "172.29.254.198"
}

resource "azurerm_subnet_route_table_association" "srv" {
  subnet_id      = azurerm_subnet.s1.id
  route_table_id = azurerm_route_table.srv.id
}






resource "azurerm_network_interface" "srv1" {
  name                = "${var.name}-srv-0"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.s1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.s1.address_prefixes[0], 5)
  }
}


resource "azurerm_linux_virtual_machine" "myterraformvm" {
  name                  = "${var.name}-srv-0"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.srv1.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.name}-srv-0"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  admin_username                  = "ubuntu"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "ubuntu"
    public_key = azurerm_ssh_public_key.rwe.public_key
  }
}


