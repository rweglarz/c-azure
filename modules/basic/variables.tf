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

variable "route_tables_params" {
  description = "parameters / next hops to generate route tables"
  default = {}
}
