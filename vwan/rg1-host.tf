resource "azurerm_public_ip" "hub1-vnet1-s1-h" {
  name                = "${var.name}-hub1-vnet1-s1-h"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "hub1-vnet1-s1-h" {
  name                = "${var.name}-hub1-vnet1-s1-h"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub1-vnet1-s1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.hub1-vnet1-s1.address_prefixes[0], 5)
    public_ip_address_id          = azurerm_public_ip.hub1-vnet1-s1-h.id
  }
}

resource "azurerm_linux_virtual_machine" "hub1-vnet1-s1-h" {
  name                = "${var.name}-hub1-vnet1-s1-h"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  size                = "Standard_DS1_v2"

  network_interface_ids = [azurerm_network_interface.hub1-vnet1-s1-h.id]

  os_disk {
    name                 = "${var.name}-hub1-vnet1-s1-h"
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
  admin_password                  = var.password
  disable_password_authentication = false

  admin_ssh_key {
    username   = "ubuntu"
    public_key = azurerm_ssh_public_key.rg1-rwe.public_key
  }

}


resource "azurerm_network_security_group" "rg1-sg" {
  name                = "${var.name}-hub1-vnet1-s1-h"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location

  security_rule {
    name                   = "data-inbound"
    priority               = 1000
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "*"
    source_port_range      = "*"
    destination_port_range = "*"
    source_address_prefixes = concat(
      [for r in var.mgmt_ips : "${r.cidr}"]
    )
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

resource "azurerm_network_interface_security_group_association" "hub1-vnet1-s1-h" {
  network_interface_id      = azurerm_network_interface.hub1-vnet1-s1-h.id
  network_security_group_id = azurerm_network_security_group.rg1-sg.id
}



output "hub1-vnet1-s1-h" {
  value = azurerm_public_ip.hub1-vnet1-s1-h.ip_address
}
