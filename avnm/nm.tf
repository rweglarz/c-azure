resource "azurerm_network_manager" "this" {
  name                = var.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  scope_accesses      = [
    "Connectivity",
    "Routing",
  ]
  # description         = "rwe network manager"
  scope {
    subscription_ids = [
      format("/subscriptions/%s", var.subscription_id)
    ]
  }
}

resource "azurerm_network_manager_network_group" "prod" {
  name               = "prod"
  network_manager_id = azurerm_network_manager.this.id
}

resource "azurerm_network_manager_network_group" "dev12" {
  name               = "dev12"
  network_manager_id = azurerm_network_manager.this.id
}
resource "azurerm_network_manager_network_group" "dev34" {
  name               = "dev34"
  network_manager_id = azurerm_network_manager.this.id
}

#region policy virtual network
resource "azurerm_policy_definition" "prod" {
  name         = "pprod"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "Policy Definition for prod Network Group"

  metadata = jsonencode({
    "category":         "Azure Virtual Network Manager"
    "networkManagerId": azurerm_network_manager.this.id
    "groupId":          azurerm_network_manager_network_group.prod.id
  })

  policy_rule = jsonencode(
    {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Network/virtualNetworks"
          },
          {
            "allOf": [
              {
                "field": "tags['env']",
                "equals": "prod"
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "addToNetworkGroup",
        "details": {
          "networkGroupId": "${azurerm_network_manager_network_group.prod.id}"
        }
      }
    }
  )
}

resource "azurerm_policy_definition" "dev12" {
  name         = "pdev12"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "Policy Definition for dev Network Group"

  metadata = jsonencode({
    "category":        "Azure Virtual Network Manager"
    "networkManagerId": azurerm_network_manager.this.id
    "groupId":          azurerm_network_manager_network_group.dev12.id
  })

  policy_rule = jsonencode(
    {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Network/virtualNetworks"
          },
          {
            "allOf": [
              {
                "field": "tags['env']",
                "equals": "dev12"
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "addToNetworkGroup",
        "details": {
          "networkGroupId": "${azurerm_network_manager_network_group.dev12.id}"
        }
      }
    }
  )
}

resource "azurerm_policy_definition" "dev34" {
  name         = "pdev34"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "Policy Definition for dev Network Group"

  metadata = jsonencode({
    "category":        "Azure Virtual Network Manager"
    "networkManagerId": azurerm_network_manager.this.id
    "groupId":          azurerm_network_manager_network_group.dev34.id
  })

  policy_rule = jsonencode(
    {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Network/virtualNetworks"
          },
          {
            "allOf": [
              {
                "field": "tags['env']",
                "equals": "dev34"
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "addToNetworkGroup",
        "details": {
          "networkGroupId": "${azurerm_network_manager_network_group.dev34.id}"
        }
      }
    }
  )
}



resource "azurerm_network_manager_connectivity_configuration" "dev" {
  name                  = "dev"
  network_manager_id    = azurerm_network_manager.this.id
  connectivity_topology = "HubAndSpoke"

  applies_to_group {
    group_connectivity  = "DirectlyConnected"
    network_group_id    = azurerm_network_manager_network_group.dev12.id
    global_mesh_enabled = false      # explicitly set default
  }
  applies_to_group {
    group_connectivity  = "DirectlyConnected"
    network_group_id    = azurerm_network_manager_network_group.dev34.id
    global_mesh_enabled = false      # explicitly set default
  }

  hub {
    resource_id   = module.sec.vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}

resource "azurerm_network_manager_connectivity_configuration" "prod" {
  name                  = "prod"
  network_manager_id    = azurerm_network_manager.this.id
  connectivity_topology = "HubAndSpoke"

  applies_to_group {
    group_connectivity  = "DirectlyConnected"
    network_group_id    = azurerm_network_manager_network_group.prod.id
    global_mesh_enabled = false      # explicitly set default
  }

  hub {
    resource_id   = module.sec.vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}



resource "azurerm_subscription_policy_assignment" "prod" {
  name                 = "prod"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.prod.id
}

resource "azurerm_subscription_policy_assignment" "dev12" {
  name                 = "dev12"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.dev12.id
}

resource "azurerm_subscription_policy_assignment" "dev34" {
  name                 = "dev34"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.dev34.id
}
#endregion



resource "azurerm_network_manager_deployment" "this" {
  network_manager_id = azurerm_network_manager.this.id
  location           = azurerm_resource_group.rg.location
  scope_access       = "Connectivity"
  configuration_ids  = [
    azurerm_network_manager_connectivity_configuration.dev.id,
    azurerm_network_manager_connectivity_configuration.prod.id,
  ]
}
