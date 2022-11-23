resource "azurerm_network_interface" "srv_sec" {
  count               = 2
  name                = "${var.name}-srv-sec-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.srv_sec[count.index].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.srv_sec[count.index].address_prefixes[0], 8)
  }
}


resource "azurerm_linux_virtual_machine" "srv_sec" {
  count                 = 2
  name                  = "${var.name}-srv-sec-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.srv_sec[count.index].id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.name}-srv-sc-${count.index}"
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


