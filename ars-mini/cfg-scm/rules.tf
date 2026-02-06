resource "scm_security_rule" "rule1" {
  name        = "network"
  folder      = var.scm_folder
  action      = "allow"

  from        = ["any"]
  to          = ["any"]
  category    = ["any"]
  source_user = ["any"]
  source      = [
    "10.0.0.0/8",
    "172.16.0.0/12",
  ]
  destination = ["0.0.0.0/0"]

  service     = ["any"]
  application = [
    "bgp", 
    "ping",
  ]
}
