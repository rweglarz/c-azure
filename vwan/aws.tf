resource "aws_ec2_managed_prefix_list_entry" "vm_fws" {
  for_each = var.pl-mgmt-csp_nat_ips==null ? {} : {
    hub1_sec_fw     = "${module.hub1_sec_fw.mgmt_ip_address}/32"
    hub2_sdwan_fw1  = "${module.hub2_sdwan_fw1.mgmt_ip_address}/32"
    hub2_sdwan_fw2  = "${module.hub2_sdwan_fw2.mgmt_ip_address}/32"
    hub4_sdwan_fw   = "${module.hub4_sdwan_fw.mgmt_ip_address}/32"
    sdwan_spoke1_fw = "${module.sdwan_spoke1_fw.mgmt_ip_address}/32"
  }
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  cidr           = each.value
  description    = "azure-${local.dname}-${each.key}"
}

resource "aws_ec2_managed_prefix_list_entry" "cloud_ngfws" {
  for_each = var.pl-mgmt-csp_nat_ips==null ? {} : {
    cloud_ngfw_hub2 =  "${azurerm_public_ip.hub2_fw.ip_address}/32"
    cloud_ngfw_hub4 =  "${azurerm_public_ip.hub4_fw.ip_address}/32"
  }
  prefix_list_id = var.pl-mgmt-csp_nat_ips
  cidr           = each.value
  description    = "azure-${local.dname}-${each.key}"
}


