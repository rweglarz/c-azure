variable "subscription_id" {
   type    = string
}
variable "tenant_id" {
   type    = string
}

variable "name" {
  description = "Name/Prefix of the deployment"
  type        = string
}

variable "region" {
  type    = string
  default = "polandcentral"
}

variable "cidr" {
  type     = string
  default  = "172.16.0.0/16"
}

variable "mgmt_ips" {
  description = "List of IPs allowed external access"
  type        = list(map(string))
}

variable "password" {
}
