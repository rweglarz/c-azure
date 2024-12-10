resource "azurerm_dns_a_record" "public" {
  for_each = {
    vwan-aws-fw          = module.aws_fw.mgmt_public_ip
    vwan-aws-srv         = module.aws_srv.public_ip
    vwan-hub1-sec-spoke1 = module.hub1_sec_spoke1_h.public_ip
    vwan-hub1-sec-spoke2 = module.hub1_sec_spoke2_h.public_ip
    vwan-hub2-spoke1-s1  = module.hub2_spoke1_s1_h.public_ip
    vwan-hub2-spoke1-s2  = module.hub2_spoke1_s2_h.public_ip
    vwan-hub2-spoke2     = module.hub2_spoke2_h.public_ip
    vwan-hub3-spoke1-s1  = module.hub3_spoke1_s1_h.public_ip
    vwan-hub4-spoke1-s1  = module.hub4_spoke1_s1_h.public_ip
    vwan-hub4-spoke1-s2  = module.hub4_spoke1_s2_h.public_ip
    vwan-hub4-spoke2-prv = module.hub4_spoke2_h_prv.public_ip
    vwan-hub2-sdwan-fw1  = module.hub2_sdwan_fw1.mgmt_ip_address
    vwan-hub2-sdwan-fw2  = module.hub2_sdwan_fw2.mgmt_ip_address
    vwan-hub4-sdwan-fw   = module.hub4_sdwan_fw.mgmt_ip_address
    vwan-sdwan-spoke1-fw = module.sdwan_spoke1_fw.mgmt_ip_address
    vwan-sdwan-spoke1    = module.sdwan_spoke1_h.public_ip,
    vwan-hub4-ext-lb     = azurerm_public_ip.hub4_ext_lb.ip_address
  }
  name = each.key
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    each.value
  ]
}


resource "azurerm_private_dns_zone" "this" {
  name                = var.private_dns_zone_name
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = {
     hub1_sec_spoke1 = module.hub1_sec_spoke1.id,
     hub2_spoke1     = module.hub2_spoke1.id,
     hub2_spoke2     = module.hub2_spoke2.id,
     hub2_dns        = module.hub2_dns.id,
     hub4_spoke1     = module.hub4_spoke1.id,
     hub4_spoke2     = module.hub4_spoke2.id,
     sdwan_spoke1    = module.sdwan_spoke1.id,
  }
  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg1.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value
}

resource "azurerm_private_dns_a_record" "this" {
  for_each = {
    aws-fw          = module.aws_fw.private_ip_list.priv[0],
    aws-s           = module.aws_srv.private_ip,
    hub2-spoke1-s1  = module.hub2_spoke1_s1_h.private_ip_address,
    hub2-spoke1-s2  = module.hub2_spoke1_s2_h.private_ip_address,
    hub2-spoke2     = module.hub2_spoke2_h.private_ip_address,
    hub4-spoke1-s1  = module.hub4_spoke1_s1_h.private_ip_address,
    hub4-spoke1-s2  = module.hub4_spoke1_s2_h.private_ip_address,
    hub4-spoke2-prv = module.hub4_spoke2_h_prv.private_ip_address,
    hub4-spoke2-pub = module.hub4_spoke2_h_pub.private_ip_address,
    sdwan-spoke1-fw = module.sdwan_spoke1_fw.private_ip_list.private[0],
    sdwan-spoke1-s  = module.sdwan_spoke1_h.private_ip_address,
    sdwan-hub2-fw1  = module.hub2_sdwan_fw1.private_ip_list.private[0],
    sdwan-hub2-fw2  = module.hub2_sdwan_fw1.private_ip_list.private[0],
    sdwan-hub4-fw   = module.hub4_sdwan_fw.private_ip_list.private[0],
  }
  name                = each.key
  resource_group_name = azurerm_resource_group.rg1.name
  zone_name           = azurerm_private_dns_zone.this.name
  ttl                 = local.dns_ttl
  records = [
    each.value
  ]
}
