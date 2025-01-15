resource "google_compute_firewall" "pan" {
  name      = "lab-${var.name}-pan-i"
  project   = var.gcp_project
  network   = var.gcp_panorama_vpc_id
  direction = "INGRESS"
  source_ranges = [
    azurerm_public_ip.ngw.ip_address,
  ]
  allow {
    protocol = "tcp"
    ports    = ["3978", "28443"]
  }
  allow {
    protocol = "icmp"
  }
}
