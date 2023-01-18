output "identity" {
  value = azurerm_kubernetes_cluster.this.identity
}

output "ingress_application_gateway_identity" {
  value = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0]
}
