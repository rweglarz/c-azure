resource "azurerm_dns_a_record" "this" {
  for_each = merge(
    { 
      for k,v in module.transit_fw: "transit_${k}" => v.public_ips["mgmt"] 
    },
    {
      onprem_fw = module.onprem_fw.public_ips["mgmt"]
    },
    { 
      for k,v in module.linux_srv: "srv_${k}" => v.public_ip 
    },
  )
  name                = format("ars-s-%s", replace(each.key, "_", "-"))
  resource_group_name = var.dns_zone_rg
  zone_name           = var.dns_zone_name
  ttl                 = 300
  records = [
    each.value
  ]
}
