resource "azurerm_public_ip" "this" {
  count               = var.associate_public_ip ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}


resource "azurerm_network_interface" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  enable_ip_forwarding = var.enable_ip_forwarding
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = try(azurerm_public_ip.this[0].id, null)

    gateway_load_balancer_frontend_ip_configuration_id = var.gwlb_fe_id
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.size

  network_interface_ids = [azurerm_network_interface.this.id]

  os_disk {
    name                 = var.name
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false

  custom_data = var.custom_data

  admin_ssh_key {
    username   = "ubuntu"
    public_key = var.public_key
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.associate_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.security_group
}


