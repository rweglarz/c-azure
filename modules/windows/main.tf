resource "azurerm_public_ip" "this" {
  count               = var.associate_public_ip ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags

  lifecycle { create_before_destroy = true }
}


resource "azurerm_network_interface" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = try(azurerm_public_ip.this[0].id, null)
  }
  tags = var.tags
}

locals {
  images = {
    server2022 = {
      publisher     = "MicrosoftWindowsServer"
      offer         = "WindowsServer"
      sku           = "2022-datacenter"
      version       = "latest"
    }
    desktop11 = {
      publisher     = "MicrosoftWindowsDesktop"
      offer         = "windows-11"
      sku           = "win11-23h2-pro"
      version       = "latest"
    }
    custom = {
      publisher     = try(var.image.publisher, "x")
      offer         = try(var.image.offer, "x")
      sku           = try(var.image.sku, "x")
      version       = try(var.image.version, "x")
    }
  }
  image = coalesce(
    can(var.image.publisher) ? local.images.custom : null,
    local.images[var.image_variant]
  )
}

resource "azurerm_windows_virtual_machine" "this" {
  name                = var.name
  computer_name       = var.computer_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.size
  admin_username      = var.username
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.image.publisher
    offer     = local.image.offer
    sku       = local.image.sku
    version   = local.image.version
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [ 
      source_image_reference 
    ]
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.associate_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.security_group
}
