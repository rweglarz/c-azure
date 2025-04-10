resource "azurerm_public_ip" "this" {
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

  ip_forwarding_enabled = var.enable_ip_forwarding

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = azurerm_public_ip.this.id
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

  plan {
    name      = "pan-prisma-access-ztna-connector"
    publisher = "paloaltonetworks"
    product   = "pan-prisma-access-ztna-connector"
  }
  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "pan-prisma-access-ztna-connector"
    sku       = "pan-prisma-access-ztna-connector"
    version   = var.sw_version
  }

  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false

  custom_data = base64encode(<<-EOT
    [General]
    model = ion 200v
    host1_name = locator.cgnx.net
    
    [License]
    key = ${var.token.key}
    secret = ${var.token.secret}
    
    [1]
    role = PublicWAN
    type = DHCP
    EOT
  )

  admin_ssh_key {
    username   = var.username
    public_key = var.public_key
  }
  boot_diagnostics {
    storage_account_uri = null
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.associate_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.security_group
}
