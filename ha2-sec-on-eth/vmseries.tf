# Public IP Address:
resource "azurerm_public_ip" "mgmt" {
  count               = 2
  name                = "${var.name}-mgmt-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}

# Network Interface:
resource "azurerm_network_interface" "mgmt" {
  count                = 2
  name                 = "${var.name}-mgmt-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.mgmt.address_prefixes[0], 4 + count.index)
    public_ip_address_id          = azurerm_public_ip.mgmt[count.index].id
  }
}

resource "azurerm_network_security_group" "mgmt" {
  name                = "${var.name}-nsg-mgmt"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                    = "management-inbound"
    priority                = 1000
    direction               = "Inbound"
    access                  = "Allow"
    protocol                = "Tcp"
    source_port_range       = "*"
    destination_port_ranges = ["443", "22"]
    source_address_prefixes = concat(
      [for r in var.mgmt_ips : "${r.cidr}"]
    )
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "mgmt" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.mgmt[count.index].id
  network_security_group_id = azurerm_network_security_group.mgmt.id
}

resource "azurerm_public_ip" "untrust" {
  count               = 1
  name                = "${var.name}-untrust-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}

# Network Interface
# id fw nic pub
# 0  0  0   0 2
# 1  0  1    
# 2  0  2
# 3  1  0   1 3
# 4  1  1
# 5  1  2
resource "azurerm_network_interface" "data" {
  count                         = 2 * 3
  name                          = "${var.name}-fw${(count.index - (count.index % 3)) / 3}-nic${count.index % 3}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.data[count.index % 3].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.data[count.index % 3].address_prefixes[0], 4 + ((count.index - (count.index % 3)) / 3))
    primary                       = true
  }
  # 1 and 2 interfaces have one secondary
  dynamic "ip_configuration" {
    for_each = [
      for i in [1] : i
      if contains([1, 2], count.index)
    ]
    content {
      name                          = "secondary"
      subnet_id                     = azurerm_subnet.data[count.index % 3].id
      private_ip_address_allocation = "Static"
      private_ip_address            = cidrhost(azurerm_subnet.data[count.index % 3].address_prefixes[0], 6)
      # this public ip will only be applied to first instance on eth1/2==1 data interface
      public_ip_address_id = (count.index == 1) ? azurerm_public_ip.untrust[0].id : null
    }
  }
}

resource "azurerm_network_security_group" "data" {
  name                = "${var.name}-nsg-data"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "data-inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
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

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "data" {
  count                     = 2 * 3
  network_interface_id      = azurerm_network_interface.data[count.index].id
  network_security_group_id = azurerm_network_security_group.data.id
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Virtual Machine
#----------------------------------------------------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "vmseries" {
  count = 2

  name                = "${var.name}-vm-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.instance_type

  disable_password_authentication = false
  admin_username                  = var.username
  admin_password                  = var.password


  # Network Interfaces:
  network_interface_ids = [
    azurerm_network_interface.mgmt[count.index].id,
    azurerm_network_interface.data[count.index * 3 + 0].id,
    azurerm_network_interface.data[count.index * 3 + 1].id,
    azurerm_network_interface.data[count.index * 3 + 2].id,
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

  # Bootstrap Information for Azure:
  custom_data = base64encode(join("\n", compact(concat(
    [for k, v in var.bootstrap_options : "${k}=${v}"],
    ["tplname=azure-ha2-${count.index}"],
  ))))
}

output "vmseries0_management_ip" {
  value = azurerm_public_ip.mgmt[0].ip_address
}

output "vmseries1_management_ip" {
  value = azurerm_public_ip.mgmt[1].ip_address
}

