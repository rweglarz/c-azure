resource "azurerm_dns_a_record" "aws-fw-1" {
  name                = "vwan-aws-fw-1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    one([for k, v in module.vm-fw-1.public_ips : v if(length(regexall("mgmt", k)) > 0)])
  ]
}

resource "azurerm_dns_a_record" "public" {
  for_each = {
    vwan-hub1-sec-fw     = module.hub1_sec_fw.mgmt_ip_address
    vwan-hub1-sec-spoke1 = module.hub1_sec_spoke1_h.public_ip
    vwan-hub2-spoke1-s1  = module.hub2_spoke1_s1_h.public_ip
    vwan-hub2-spoke1-s2  = module.hub2_spoke1_s2_h.public_ip
    vwan-hub2-spoke2     = module.hub2_spoke2_h.public_ip
    vwan-hub4-spoke1-s1  = module.hub4_spoke1_s1_h.public_ip
    vwan-hub4-spoke1-s2  = module.hub4_spoke1_s2_h.public_ip
    vwan-hub4-spoke2-prv = module.hub4_spoke2_h_prv.public_ip
    vwan-hub2-sdwan-fw   = module.hub2_sdwan_fw.mgmt_ip_address
    vwan-hub4-sdwan-fw   = module.hub4_sdwan_fw.mgmt_ip_address
    vwan-sdwan-spoke1-fw = module.sdwan_spoke1_fw.mgmt_ip_address
    vwan-sdwan-spoke1    = module.sdwan_spoke1_h.public_ip,
    vwan-ipsec-hub2-fw1  = module.ipsec_hub2_fw1.mgmt_ip_address
    vwan-ipsec-hub2-fw2  = module.ipsec_hub2_fw2.mgmt_ip_address
    vwan-ipsec-spoke1-fw = module.ipsec_spoke1_fw.mgmt_ip_address
    vwan-ipsec-hubs      = local.public_ip["ipsec_hub2_fw1"][0]
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
  name                = "vwan.test"
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = {
     hub2_spoke1  = module.hub2_spoke1.id,
     hub2_spoke2  = module.hub2_spoke2.id,
     hub2_dns     = module.hub2_dns.id,
     hub4_spoke1  = module.hub4_spoke1.id,
     hub4_spoke2  = module.hub4_spoke2.id,
     sdwan_spoke1 = module.sdwan_spoke1.id,
  }
  name                  = each.key
  resource_group_name   = azurerm_resource_group.rg1.name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value
}

resource "azurerm_private_dns_a_record" "this" {
  for_each = {
    hub2-spoke1-s1  = module.hub2_spoke1_s1_h.private_ip_address,
    hub2-spoke1-s2  = module.hub2_spoke1_s2_h.private_ip_address,
    hub2-spoke2     = module.hub2_spoke2_h.private_ip_address,
    hub4-spoke1-s1  = module.hub4_spoke1_s1_h.private_ip_address,
    hub4-spoke1-s2  = module.hub4_spoke1_s2_h.private_ip_address,
    hub4-spoke2-prv = module.hub4_spoke2_h_prv.private_ip_address,
    hub4-spoke2-pub = module.hub4_spoke2_h_pub.private_ip_address,
    sdwan-spoke1    = module.sdwan_spoke1_h.private_ip_address,
    sdwan-hub2      = module.hub2_sdwan_fw.private_ip_list.private[0],
    sdwan-hub4      = module.hub4_sdwan_fw.private_ip_list.private[0],
    aws-internal    = module.vm-fw-1.private_ip_list.priv[0],
    ipsec-hub2-fw1  = module.ipsec_hub2_fw1.private_ip_list.private[0],
    ipsec-hub2-fw2  = module.ipsec_hub2_fw2.private_ip_list.private[0],
  }
  name                = each.key
  resource_group_name = azurerm_resource_group.rg1.name
  zone_name           = azurerm_private_dns_zone.this.name
  ttl                 = local.dns_ttl
  records = [
    each.value
  ]
}
