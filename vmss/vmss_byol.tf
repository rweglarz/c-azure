resource "azurerm_linux_virtual_machine_scale_set" "byol" {
  name                = "${var.name}-vmss-byol"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.instance_type
  instances           = var.fw_instances_byol
  upgrade_mode        = "Manual"

  disable_password_authentication = true
  admin_username                  = var.username
  admin_ssh_key {
    public_key = azurerm_ssh_public_key.rwe.public_key
    username   = var.username
  }

  network_interface {
    name                          = "mgmt"
    primary                       = true
    enable_ip_forwarding          = false
    enable_accelerated_networking = false

    ip_configuration {
      name      = "pri"
      primary   = true
      subnet_id = azurerm_subnet.mgmt.id
    }
  }
  dynamic "network_interface" {
    for_each = [0, 1, 2]
    content {
      name                          = "eth-${network_interface.value + 1}"
      primary                       = false
      enable_ip_forwarding          = true
      enable_accelerated_networking = true

      ip_configuration {
        name      = "pri"
        primary   = true
        subnet_id = azurerm_subnet.data[network_interface.value].id

        load_balancer_backend_address_pool_ids = [local.lbsp[network_interface.value]]
      }
      /*
      depends_on = [
        network_interface.value > 0 ? azurerm_lb_backend_address_pool.this[network_interface.value - 1].id : null
      ]
      */
    }
  }

  plan {
    name      = "byol"
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = "byol"
    version   = var.fw_version
  }
  os_disk {
    caching = "ReadWrite"
    //  storage_account_type = "Premium_LRS"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(join("\n", compact(concat(
    [for k, v in var.bootstrap_options_byol : "${k}=${v}"],
  ))))

  depends_on = [
    azurerm_subnet_nat_gateway_association.mgmt,
  ]
}