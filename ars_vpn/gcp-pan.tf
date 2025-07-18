resource "google_compute_firewall" "pan" {
  name      = "lab-${var.name}-pan-i"
  project   = var.gcp_project
  network   = var.gcp_panorama_vpc_id
  direction = "INGRESS"
  source_ranges = concat(
    [for k,v in module.left_u_hub_fw: "${v.mgmt_ip_address}/32"],
    [for k,v in module.left_b_hub_fw: "${v.mgmt_ip_address}/32"],
    "{module.right_hub_fw.mgmt_ip_address}/32",
    "{module.left_u_ipsec_fw1.mgmt_ip_address}/32",
    "{module.left_u_ipsec_fw2.mgmt_ip_address}/32",
    "{module.left_b_ipsec_fw1.mgmt_ip_address}/32",
    "{module.left_b_ipsec_fw2.mgmt_ip_address}/32",
    "{module.right_env_fw1.mgmt_ip_address}/32",
  )
  allow {
    protocol = "tcp"
    ports    = ["3978", "28443"]
  }
  allow {
    protocol = "icmp"
  }
}
