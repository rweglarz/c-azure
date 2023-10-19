resource "azurerm_dns_a_record" "aws-fw-1" {
  name                = "vwan-aws-fw-1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    one([for k, v in module.vm-fw-1.public_ips : v if(length(regexall("mgmt", k)) > 0)])
  ]
}

resource "azurerm_dns_a_record" "hub1_sec_fw" {
  name                = "vwan-hub1-sec-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub1_sec_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "hub1_sec_spoke1_h" {
  name                = "vwan-hub1-sec-spoke1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub1_sec_spoke1_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub2_spoke1_s1_h" {
  name                = "vwan-hub2-spoke1-s1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub2_spoke1_s1_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub2_spoke1_s2_h" {
  name                = "vwan-hub2-spoke1-s2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub2_spoke1_s2_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub2_spoke2_h" {
  name                = "vwan-hub2-spoke2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub2_spoke2_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub4_spoke1_s1_h" {
  name                = "vwan-hub4-spoke1-s1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub4_spoke1_s1_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub4_spoke1_s2_h" {
  name                = "vwan-hub4-spoke1-s2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub4_spoke1_s2_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub4_spoke2_h_prv" {
  name                = "vwan-hub4-spoke2-prv"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub4_spoke2_h_prv.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub2_sdwan_fw" {
  name                = "vwan-hub2-sdwan-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub2_sdwan_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "hub4_sdwan_fw" {
  name                = "vwan-hub4-sdwan-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.hub4_sdwan_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "sdwan_spoke1_fw" {
  name                = "vwan-sdwan-spoke1-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.sdwan_spoke1_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "sdwan_spoke1_h" {
  name                = "vwan-sdwan-spoke1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.sdwan_spoke1_h.public_ip,
  ]
}

resource "azurerm_dns_a_record" "ipsec_hub2_fw1" {
  name                = "vwan-ipsec-hub2-fw1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.ipsec_hub2_fw1.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "ipsec_hub2_fw2" {
  name                = "vwan-ipsec-hub2-fw2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.ipsec_hub2_fw2.mgmt_ip_address
  ]
}


resource "azurerm_dns_a_record" "ipsec_spoke1_fw" {
  name                = "vwan-ipsec-spoke1-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = local.dns_ttl
  records = [
    module.ipsec_spoke1_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "ipsec_hubs" {
  name                = "vwan-ipsec-hubs"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    local.public_ip["ipsec_hub2_fw1"][0]
  ]
}

resource "azurerm_dns_a_record" "hub4_ext_lb" {
  name                = "vwan-hub4-ext-lb"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 60
  records = [
    azurerm_public_ip.hub4_ext_lb.ip_address
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
