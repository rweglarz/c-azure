variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "mgmt_cidrs" {
  type = list(any)
}

variable "split_route_tables" {
  description = "mgmt ips route to internet"
  default = {}
}
