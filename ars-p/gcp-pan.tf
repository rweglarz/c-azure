resource "google_compute_firewall" "pan" {
  name      = "lab-${var.name}-pan-i"
  project   = var.gcp_project
  network   = var.gcp_panorama_vpc_id
  direction = "INGRESS"
  source_ranges = concat(
    [ 
      for k,v in module.transit_fw: v.public_ips["mgmt"] 
    ],
    [
      module.onprem_fw.public_ips["mgmt"]
    ],
  )
  allow {
    protocol = "tcp"
    ports    = ["3978", "28443"]
  }
  allow {
    protocol = "icmp"
  }
}
