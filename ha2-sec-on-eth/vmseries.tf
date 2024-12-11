locals {
  subnet_mask_length = 27
  fw_ip = {
    mgmt = {
      fw0 = cidrhost(module.vnet_sec.subnets.mgmt.address_prefixes[0], 4 + 0),
      fw1 = cidrhost(module.vnet_sec.subnets.mgmt.address_prefixes[0], 4 + 1),
    }
    ha2 = {
      fw0 = cidrhost(module.vnet_sec.subnets.ha2.address_prefixes[0], 4 + 0),
      fw1 = cidrhost(module.vnet_sec.subnets.ha2.address_prefixes[0], 4 + 1),
    }
    public = {
      fw0 = cidrhost(module.vnet_sec.subnets.public.address_prefixes[0], 4 + 0),
      fw1 = cidrhost(module.vnet_sec.subnets.public.address_prefixes[0], 4 + 1),
      fws = cidrhost(module.vnet_sec.subnets.public.address_prefixes[0], 4 + 2),
    }
    private = {
      fw0 = cidrhost(module.vnet_sec.subnets.private.address_prefixes[0], 4 + 0),
      fw1 = cidrhost(module.vnet_sec.subnets.private.address_prefixes[0], 4 + 1),
      fws = cidrhost(module.vnet_sec.subnets.private.address_prefixes[0], 4 + 2),
    }
  }
}

resource "azurerm_public_ip" "mgmt" {
  count               = 2
  name                = "${var.name}-mgmt-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}

resource "azurerm_network_interface" "mgmt" {
  count                = 2
  name                 = "${var.name}-fw${count.index}-mgmt"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  ip_forwarding_enabled = false

  ip_configuration {
    name                          = "primary"
    subnet_id                     = module.vnet_sec.subnets.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.fw_ip.mgmt["fw${count.index}"]
    public_ip_address_id          = azurerm_public_ip.mgmt[count.index].id
  }
}

resource "azurerm_network_interface" "ha2" {
  count                = 2
  name                 = "${var.name}-fw${count.index}-ha2"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location

  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = module.vnet_sec.subnets.ha2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.fw_ip.ha2["fw${count.index}"]
  }
}

resource "azurerm_network_interface" "public" {
  count                = 2
  name                 = "${var.name}-fw${count.index}-public"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location

  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "primary"
    primary                       = true
    subnet_id                     = module.vnet_sec.subnets.public.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.fw_ip.public["fw${count.index}"]
  }
  dynamic "ip_configuration" {
    for_each = (count.index==0) ? [1] : []
    content {
      name                          = "secondary-main"
      subnet_id                     = module.vnet_sec.subnets.public.id
      private_ip_address_allocation = "Static"
      private_ip_address            = local.fw_ip.public["fws"]
      public_ip_address_id          = azurerm_public_ip.untrust["main"].id
    }
  }
  dynamic "ip_configuration" {
    for_each = (count.index==0) ? var.additional_untrust_ips: {}
    content {
      name                          = "secondary-${ip_configuration.key}"
      subnet_id                     = module.vnet_sec.subnets.public.id
      private_ip_address_allocation = "Static"
      private_ip_address            = cidrhost(module.vnet_sec.subnets.public.address_prefixes[0], ip_configuration.value.idx)
      public_ip_address_id          = azurerm_public_ip.untrust[ip_configuration.key].id
    }
  }
}

resource "azurerm_network_interface_security_group_association" "public" {
  count = 2
  network_interface_id      = azurerm_network_interface.public[count.index].id
  network_security_group_id = module.basic.sg_id.wide-open
}

resource "azurerm_network_interface" "private" {
  count                = 2
  name                 = "${var.name}-fw${count.index}-private"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location

  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "primary"
    primary                       = true
    subnet_id                     = module.vnet_sec.subnets.private.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.fw_ip.private["fw${count.index}"]
  }
  dynamic "ip_configuration" {
    for_each = (count.index==0) ? [1]: []
    content {
      name                          = "secondary-${count.index}"
      subnet_id                     = module.vnet_sec.subnets.private.id
      private_ip_address_allocation = "Static"
      private_ip_address            = local.fw_ip.private["fws"]
    }
  }
}

resource "azurerm_public_ip" "untrust" {
  for_each = merge(
    { main = { idx = 6 } },
    var.additional_untrust_ips
  )
  name                = "${var.name}-fw-untrust-${each.key}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]

  idle_timeout_in_minutes = 8
}


resource "azurerm_linux_virtual_machine" "vmseries" {
  count = 2

  name                = "${var.name}-fw-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  zone                = var.availabilty_zones[count.index]
  size                = var.instance_type

  disable_password_authentication = false
  admin_username                  = var.username
  admin_password                  = var.password

  network_interface_ids = [
    azurerm_network_interface.mgmt[count.index].id,
    azurerm_network_interface.ha2[count.index].id,
    azurerm_network_interface.public[count.index].id,
    azurerm_network_interface.private[count.index].id,
  ]

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
    name    = "${var.name}-osdisk-${count.index}"
    caching = "ReadWrite"
    //  storage_account_type = "Premium_LRS"
    storage_account_type = "Standard_LRS"
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  custom_data = base64encode(join(";", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
    [
      "vm-auth-key=${panos_vm_auth_key.this.auth_key}",
      "tplname=${panos_panorama_template_stack.azure_ha2[count.index].name}",
    ],
  ))))
}

output "vmseries0_management_ip" {
  value = azurerm_public_ip.mgmt[0].ip_address
}

output "vmseries1_management_ip" {
  value = azurerm_public_ip.mgmt[1].ip_address
}

output "public_ip_untrust" {
  value = { for k,v in azurerm_public_ip.untrust: k => v.ip_address }
}
