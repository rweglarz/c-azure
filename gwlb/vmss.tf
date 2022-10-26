resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "${var.name}-fw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.instance_type
  instances           = 2

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
  network_interface {
      name                          = "eth-1-1"
      primary                       = false
      enable_ip_forwarding          = true
      enable_accelerated_networking = true

      ip_configuration {
        name      = "pri"
        primary   = true
        subnet_id = azurerm_subnet.data.id

        load_balancer_backend_address_pool_ids = [
          azurerm_lb_backend_address_pool.gwlb.id,
        ] 
        //gateway_load_balancer_frontend_ip_configuration_id = azurerm_lb.gwlb.frontend_ip_configuration[0].id
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
    version   = var.fw_ver
  }
  os_disk {
    caching = "ReadWrite"
    //  storage_account_type = "Premium_LRS"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(join("\n", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
  ))))

  depends_on = [
    azurerm_subnet_nat_gateway_association.this,
  ]
}
