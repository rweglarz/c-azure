resource "panos_address_object" "cngfw" {
  count = var.cloud_ngfw_panorama_config!=null ? 1 : 0
  device_group  = local.cngfw.device_group

  name  = "cngfw standalone"
  value = azurerm_public_ip.cloud_ngfw.ip_address

  lifecycle { create_before_destroy = true }
}


resource "panos_security_rule_group" "this" {
  count = var.cloud_ngfw_panorama_config!=null ? 1 : 0
  device_group  = local.cngfw.device_group

  rule {
    name                  = "inbound to apps"
    source_zones          = ["Public"]
    source_addresses      = [
      "safe ips",
    ]
    source_users          = ["any"]
    destination_zones     = ["Private"]
    destination_addresses = [
      panos_address_object.cngfw[0].name
    ]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    group                 = "almost default"
    log_setting           = "panka"
  }

  rule {
    name                  = "east-west"
    source_zones          = ["Private"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["Private"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    group                 = "almost default"
    log_setting           = "panka"
  }

  rule {
    name                  = "outbound"
    source_zones          = ["Private"]
    source_addresses      = ["any"]
    source_users          = ["any"]
    destination_zones     = ["Public"]
    destination_addresses = ["any"]
    applications          = ["any"]
    services              = ["any"]
    categories            = ["any"]
    action                = "allow"
    group                 = "almost default"
    log_setting           = "panka"
  }

  lifecycle { create_before_destroy = true }
}
