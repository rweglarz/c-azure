resource "azurerm_public_ip" "fw_lb_ext_1" {
  name                = "${var.name}-fw-lb-ext-1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}

resource "azurerm_public_ip" "fw_lb_ext_2" {
  name                = "${var.name}-fw-lb-ext-2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
}

resource "azurerm_lb" "fw_ext" {
  name                = "${var.name}-fw-ext"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "ext-1"
    public_ip_address_id = azurerm_public_ip.fw_lb_ext_1.id
  }
  frontend_ip_configuration {
    name                 = "ext-2"
    public_ip_address_id = azurerm_public_ip.fw_lb_ext_2.id
  }
}

resource "azurerm_lb" "fw_int" {
  name                = "${var.name}-fw-int"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"


  frontend_ip_configuration {
    name                          = "ilb"
    subnet_id                     = module.vnet_sec.subnets["private"].id
    private_ip_address            = cidrhost(module.vnet_sec.subnets["private"].address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_probe" "fw_int" {
  for_each = toset([
    "54321",
  ])
  name            = "tcp-probe-${each.key}"
  loadbalancer_id = azurerm_lb.fw_int.id
  protocol        = "Tcp"
  port            = each.key
}


resource "azurerm_lb_probe" "fw_ext" {
  for_each = toset([
    "22",
    "80",
    "54321",
  ])
  name            = "tcp-probe-${each.key}"
  loadbalancer_id = azurerm_lb.fw_ext.id
  protocol        = "Tcp"
  port            = each.key
}


resource "azurerm_lb_rule" "fw_ext_1" {
  for_each = toset([
    "22",
    "80",
  ])
  name = "ext-1-${each.key}"

  loadbalancer_id                = azurerm_lb.fw_ext.id
  frontend_ip_configuration_name = "ext-1"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.fw_ext.id]
  probe_id                       = azurerm_lb_probe.fw_ext[each.key].id

  enable_floating_ip    = true
  disable_outbound_snat = true

  protocol      = "Tcp"
  frontend_port = each.key
  backend_port  = each.key
}

resource "azurerm_lb_rule" "fw_ext_2" {
  for_each = toset([
    "22",
    "80",
  ])
  name = "ext-2-${each.key}"

  loadbalancer_id                = azurerm_lb.fw_ext.id
  frontend_ip_configuration_name = "ext-2"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.fw_ext.id]
  probe_id                       = azurerm_lb_probe.fw_ext[each.key].id

  enable_floating_ip    = true
  disable_outbound_snat = true

  protocol      = "Tcp"
  frontend_port = each.key
  backend_port  = each.key
}



resource "azurerm_lb_backend_address_pool" "fw_ext" {
  name            = "${var.name}-fw-ext"
  loadbalancer_id = azurerm_lb.fw_ext.id
}


resource "azurerm_lb_rule" "ilb" {
  name = "${var.name}-lb-r-srv"

  loadbalancer_id                = azurerm_lb.fw_int.id
  frontend_ip_configuration_name = "ilb"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.fw_int.id]
  probe_id                       = azurerm_lb_probe.fw_int["54321"].id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}

resource "azurerm_lb_backend_address_pool" "fw_int" {
  name            = "${var.name}-ilb"
  loadbalancer_id = azurerm_lb.fw_int.id
}
