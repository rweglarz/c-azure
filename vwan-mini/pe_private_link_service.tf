module "vnet_pl_app" {
  source              = "../modules/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name          = "${var.name}-pl-app"
  address_space = ["192.168.1.0/24"]

  subnets = {
    app = {
      idx = 0
      associate_nsg             = true
      network_security_group_id = module.basic.sg_id.mgmt
    },
    pls = {
      idx = 2
    },
  }
}

module "vm_pl_app" {
  source = "../modules/linux"

  name                = "${var.name}-pl-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = module.vnet_pl_app.subnets.app.id
  private_ip_address  = cidrhost(module.vnet_pl_app.subnets.app.address_prefixes[0], 6)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
}


resource "azurerm_lb" "pl_app" {
  name                = "${var.name}-pl_app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "pl-app"
    subnet_id                     = module.vnet_pl_app.subnets.app.id
    private_ip_address            = cidrhost(module.vnet_pl_app.subnets.app.address_prefixes[0], 5)
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "pl_app" {
  name            = "${var.name}-pl-app"
  loadbalancer_id = azurerm_lb.pl_app.id
}

resource "azurerm_lb_probe" "pl_app" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.pl_app.id
  protocol        = "Tcp"
  port            = 80
}


resource "azurerm_lb_rule" "pl_app" {
  name = "pl-app"

  loadbalancer_id                = azurerm_lb.pl_app.id
  frontend_ip_configuration_name = "pl-app"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.pl_app.id]
  probe_id                       = azurerm_lb_probe.pl_app.id

  disable_outbound_snat = true

  protocol      = "All"
  frontend_port = 0
  backend_port  = 0
}


resource "azurerm_private_link_service" "pl_app" {
  name                = "${var.name}-pl-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  visibility_subscription_ids                 = [
    var.subscription_id,
  ]
  auto_approval_subscription_ids              = [
    var.subscription_id,
  ]
  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.pl_app.frontend_ip_configuration[0].id
  ]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address_version = "IPv4"
    subnet_id                  = module.vnet_pl_app.subnets.pls.id
    primary                    = true
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "pl_app" {
  network_interface_id    = module.vm_pl_app.network_interface_id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.pl_app.id
}



resource "azurerm_private_endpoint" "pl_app" {
  for_each = local.pe_subnets

  name                = "${var.name}-pl-app-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = each.key
    private_connection_resource_id = azurerm_private_link_service.pl_app.id
    is_manual_connection           = false
  }
}
