
resource "azurerm_public_ip" "srv_sa" {
  name                = "${var.name}-srv_sa"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "srv_sa" {
  name                = "${var.name}-srv_sa"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.app.address_prefixes[0], 25)
    public_ip_address_id          = azurerm_public_ip.srv_sa.id

    gateway_load_balancer_frontend_ip_configuration_id = azurerm_lb.gwlb.frontend_ip_configuration[0].id
  }
}

resource "azurerm_linux_virtual_machine" "srv_sa" {
  name                = "${var.name}-srv-sa"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_DS1_v2"

  network_interface_ids = [azurerm_network_interface.srv_sa.id]

  os_disk {
    name                 = "${var.name}-srv_sa"
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
    public_key = azurerm_ssh_public_key.rwe.public_key
  }

}


resource "azurerm_network_security_group" "srv_sa" {
  name                = "${var.name}-srv_sa"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

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

resource "azurerm_network_interface_security_group_association" "srv_sa" {
  network_interface_id      = azurerm_network_interface.srv_sa.id
  network_security_group_id = azurerm_network_security_group.srv_sa.id
}



output "srv_sa" {
  value = azurerm_public_ip.srv_sa.ip_address
}
