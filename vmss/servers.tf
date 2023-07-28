module "srv_sec" {
  source = "../modules/linux"

  name                = "${var.name}-srv-sec"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.sec_srv.id
  private_ip_address  = cidrhost(azurerm_subnet.sec_srv.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}

module "srv_spoke_a_11" {
  source = "../modules/linux"

  name                = "${var.name}-srv-spoke-a-11"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.spoke_a_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.spoke_a_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}

module "srv_spoke_a_12" {
  source = "../modules/linux"

  name                = "${var.name}-srv-spoke-a-12"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.spoke_a_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.spoke_a_s1.address_prefixes[0], 6)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}

module "srv_spoke_a_2" {
  source = "../modules/linux"

  name                = "${var.name}-srv-spoke-a-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.spoke_a_s2.id
  private_ip_address  = cidrhost(azurerm_subnet.spoke_a_s2.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}


module "srv_spoke_b_1" {
  source = "../modules/linux"

  name                = "${var.name}-srv-spoke-b-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.spoke_b_s1.id
  private_ip_address  = cidrhost(azurerm_subnet.spoke_b_s1.address_prefixes[0], 5)
  password            = var.password
  public_key          = azurerm_ssh_public_key.this.public_key
  security_group      = module.basic.sg_id["mgmt"]
  associate_nsg       = true
}



