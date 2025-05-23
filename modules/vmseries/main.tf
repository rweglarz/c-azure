resource "azurerm_public_ip" "this" {
  for_each            = { for k, v in var.interfaces : k => v if lookup(v, "public_ip", false) == true }
  resource_group_name = var.resource_group_name
  location            = var.location

  name              = "${var.name}-${each.key}"
  allocation_method = "Static"
  sku               = "Standard"
  zones             = [1, 2, 3]
}

resource "azurerm_network_interface" "this" {
  for_each            = var.interfaces
  resource_group_name = var.resource_group_name
  location            = var.location

  name                   = "${var.name}-${each.key}"

  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = contains(keys(each.value), "private_ip_address") ? "Static" : "Dynamic"
    private_ip_address            = lookup(each.value, "private_ip_address", null)
    primary                       = true
    public_ip_address_id          = lookup(each.value, "public_ip", false) == true ? azurerm_public_ip.this[each.key].id : null
  }
}

locals {
  interfaces = [
    for i in range(length(var.interfaces)) : one([
      for k, v in var.interfaces : azurerm_network_interface.this[k].id if i == v.device_index
    ])
  ]
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each                = { for k, v in var.interfaces : k => v if contains(keys(v), "load_balancer_backend_address_pool_id") }
  ip_configuration_name   = "primary"
  network_interface_id    = azurerm_network_interface.this[each.key].id
  backend_address_pool_id = each.value["load_balancer_backend_address_pool_id"]
}

resource "azurerm_linux_virtual_machine" "this" {
  resource_group_name = var.resource_group_name
  location            = var.location

  name = var.name
  size = var.size

  disable_password_authentication = false
  admin_username                  = var.username
  admin_password                  = var.password

  network_interface_ids = local.interfaces

  plan {
    name      = var.airs ? "airs-byol" : "byol"
    publisher = "paloaltonetworks"
    product   = var.airs ? "airs-flex" : "vmseries-flex"
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = var.airs ? "airs-flex" : "vmseries-flex"
    sku       = var.airs ? "airs-byol" : "byol"
    version   = var.panos
  }

  os_disk {
    name                 = var.name
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  custom_data = base64encode(join("\n", concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  )))
}
