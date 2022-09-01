resource "azurerm_network_interface" "srv" {
  count               = 2
  name                = "${var.name}-srv-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  ip_configuration {
    name                          = "eth0"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.app.address_prefixes[0], 10 + count.index)

  }
}

resource "azurerm_network_interface_backend_address_pool_association" "srv" {
  count = 2
  network_interface_id    = azurerm_network_interface.srv[count.index].id
  ip_configuration_name   = "eth0"
  backend_address_pool_id = azurerm_lb_backend_address_pool.srv.id
}


resource "azurerm_linux_virtual_machine" "srv" {
  count                 = 2
  name                  = "${var.name}-srv-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.srv[count.index].id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.name}-srv-${count.index}"
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

  custom_data = filebase64("server-init.sh")

  admin_ssh_key {
    username   = "ubuntu"
    public_key = azurerm_ssh_public_key.rwe.public_key
  }
}




resource "azurerm_network_interface_security_group_association" "srv" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.srv[count.index].id
  network_security_group_id = azurerm_network_security_group.srv.id
}



resource "azurerm_network_security_group" "srv" {
  name                = "${var.name}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "data-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "data-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}
