resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version

  role_based_access_control_enabled = true

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode
    outbound_type       = var.outbound_type
  }

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_A2_v2"
    os_disk_size_gb = 30
    vnet_subnet_id  = var.subnet_id
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
    tags = merge(
      var.tags,
      {
        mnodepool = "default"
      }
    )
  }
  api_server_access_profile {
    authorized_ip_ranges = var.mgmt_cidrs
  }

  dynamic "ingress_application_gateway" {
    for_each = var.application_gateway ? { id = var.application_gateway_id } : {}
    content {
      gateway_id = ingress_application_gateway.value
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = "pool1"
  node_count            = var.node_count
  vm_size               = "Standard_D3_v2"
  os_disk_size_gb       = 30
  vnet_subnet_id        = var.subnet_id
  tags = merge(
    var.tags,
    {
      mnodepool = "pool1"
    }
  )
}
