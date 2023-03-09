resource "azurerm_dns_a_record" "aws-fw-1" {
  name                = "vwan-aws-fw-1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    one([for k, v in module.vm-fw-1.public_ips : v if(length(regexall("mgmt", k)) > 0)])
  ]
}

resource "azurerm_dns_a_record" "hub1_sec_fw" {
  name                = "vwan-hub1-sec-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub1_sec_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "hub1_sec_spoke1_h" {
  name                = "vwan-hub1-sec-spoke1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub1_sec_spoke1_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub1_spoke1_h" {
  name                = "vwan-hub1-spoke1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub1_spoke1_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub1_spoke2_h" {
  name                = "vwan-hub1-spoke2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub1_spoke2_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub2_sec_fw" {
  name                = "vwan-hub2-sec-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub2_sec_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "hub2_sec_spoke1_h" {
  name                = "vwan-hub2-sec-spoke1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub2_sec_spoke1_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub2_spoke1_h" {
  name                = "vwan-hub2-spoke1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub2_spoke1_h.public_ip
  ]
}

resource "azurerm_dns_a_record" "hub2_spoke2_h" {
  name                = "vwan-hub2-spoke2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub2_spoke2_h.public_ip
  ]
}


resource "azurerm_dns_a_record" "hub2_sdwan_fw1" {
  name                = "vwan-hub2-sdwan-fw1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub2_sdwan_fw1.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "hub2_sdwan_fw2" {
  name                = "vwan-hub2-sdwan-fw2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.hub2_sdwan_fw2.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "sdwan_spoke1_fw" {
  name                = "vwan-sdwan-spoke1-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.sdwan_spoke1_fw.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "ipsec_hub1_fw1" {
  name                = "vwan-ipsec-hub1-fw1"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.ipsec_hub1_fw1.mgmt_ip_address
  ]
}

resource "azurerm_dns_a_record" "ipsec_hub1_fw2" {
  name                = "vwan-ipsec-hub1-fw2"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
  records = [
    module.ipsec_hub1_fw2.mgmt_ip_address
  ]
}


resource "azurerm_dns_a_record" "ipsec_spoke1_fw" {
  name                = "vwan-ipsec-spoke1-fw"
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 600
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
    local.public_ip["ipsec_hub1_fw2"][0]
  ]
}


