resource "google_compute_firewall" "pan" {
  name      = "lab-${var.name}-pan-i"
  project   = var.gcp_project
  network   = var.gcp_panorama_vpc_id
  direction = "INGRESS"
  source_ranges = [
    "172.16.0.0/12",
    module.aws_fw.mgmt_public_ip,
    azurerm_public_ip.hub1_sec_ngw.ip_address,
    module.hub2_sdwan_fw1.mgmt_ip_address,
    module.hub2_sdwan_fw2.mgmt_ip_address,
    module.hub4_sdwan_fw.mgmt_ip_address,
    module.sdwan_spoke1_fw.mgmt_ip_address,
    azurerm_public_ip.hub2_fw.ip_address,
    azurerm_public_ip.hub4_fw.ip_address,
    azurerm_public_ip.hub4_fw_e.ip_address,
  ]
  allow {
    protocol = "tcp"
    ports    = ["3978", "28443"]
  }
  allow {
    protocol = "icmp"
  }
}
