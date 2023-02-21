output "backend_address_pool_ids" {
  value = {
    obew = azurerm_lb_backend_address_pool.obew.id
  }
}
