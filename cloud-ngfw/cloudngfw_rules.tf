resource "azurerm_palo_alto_local_rulestack" "this" {
  name                  = join("", [var.name, var.cloud_ngfw_panorama_config!=null ? "-not-used" : ""])
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  vulnerability_profile = "BestPractice"
  url_filtering_profile = "BestPractice"
}

resource "azurerm_palo_alto_local_rulestack_rule" "inbound_app1" {
  name         = "inbound-app1"
  rulestack_id = azurerm_palo_alto_local_rulestack.this.id
  priority     = 1001
  action       = "Allow"


  source {
    cidrs = ["any"]
  }
  destination {
    cidrs = ["${azurerm_public_ip.cloud_ngfw[0].ip_address}/32"]
  }
  applications    = ["any"]
  protocol        = "TCP:80"
  logging_enabled = true
}

resource "azurerm_palo_alto_local_rulestack_rule" "inbound_app2" {
  name         = "inbound-app2"
  rulestack_id = azurerm_palo_alto_local_rulestack.this.id
  priority     = 1002
  action       = "Allow"


  source {
    cidrs = ["any"]
  }
  destination {
    cidrs = ["${azurerm_public_ip.cloud_ngfw[1].ip_address}/32"]
  }
  applications    = ["any"]
  protocol        = "TCP:80"
  logging_enabled = true
}

resource "azurerm_palo_alto_local_rulestack_rule" "ew" {
  name         = "ew"
  rulestack_id = azurerm_palo_alto_local_rulestack.this.id
  priority     = 1300
  action       = "Allow"


  source {
    cidrs = ["172.16.0.0/12"]
  }
  destination {
    cidrs = ["172.16.0.0/12"]
  }
  applications    = ["any"]
  logging_enabled = true
}

resource "azurerm_palo_alto_local_rulestack_rule" "outbound-web" {
  name         = "outbound-web"
  rulestack_id = azurerm_palo_alto_local_rulestack.this.id
  priority     = 1500
  action       = "Allow"


  source {
    cidrs = ["172.16.0.0/12"]
  }
  destination {
    cidrs = ["172.16.0.0/12"]
  }
  negate_destination = true
  applications = [
    "ssl",
    "web-browsing",
  ]
  logging_enabled = true
}

resource "azurerm_palo_alto_local_rulestack_rule" "outbound" {
  name         = "outbound"
  rulestack_id = azurerm_palo_alto_local_rulestack.this.id
  priority     = 1600
  action       = "Allow"


  source {
    cidrs = ["172.16.0.0/12"]
  }
  destination {
    cidrs = ["172.16.0.0/12"]
  }
  negate_destination = true
  applications    = ["any"]
  logging_enabled = true
}


resource "azurerm_palo_alto_local_rulestack_rule" "deny" {
  name         = "deny-any-any"
  rulestack_id = azurerm_palo_alto_local_rulestack.this.id
  priority     = 9999
  action       = "DenySilent"


  source {
    cidrs = ["any"]
  }
  destination {
    cidrs = ["any"]
  }
  applications    = ["any"]
  logging_enabled = true
}
