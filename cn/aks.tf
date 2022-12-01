resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.name}-k8s1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "k8s1"
  kubernetes_version  = var.kubernetes_version

  role_based_access_control_enabled = true

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    outbound_type  = "userAssignedNATGateway"
  }

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_A2_v2"
    os_disk_size_gb = 30
    vnet_subnet_id  = azurerm_subnet.aks.id
  }
  api_server_authorized_ip_ranges = concat(
    [for r in var.mgmt_ips : "${r.cidr}"],
    ["${azurerm_public_ip.ngw.ip_address}/32"],
    [var.panorama1_ip, var.panorama2_ip],
  )

  ingress_application_gateway {
    gateway_name = "${var.name}-k8s-appgw"
    subnet_id    = azurerm_subnet.appgw.id
  }
  depends_on = [
    azurerm_subnet_nat_gateway_association.aks,
  ]
}
resource "azurerm_kubernetes_cluster_node_pool" "this" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = "pool1"
  node_count            = 2
  vm_size               = "Standard_D3_v2"
  os_disk_size_gb       = 30
  vnet_subnet_id        = azurerm_subnet.aks.id
}


provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.this.kube_config.0.host
  username               = azurerm_kubernetes_cluster.this.kube_config.0.username
  password               = azurerm_kubernetes_cluster.this.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)

  load_config_file = "false"
}


/*
output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.this.kube_config_raw
}
*/
