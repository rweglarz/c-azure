variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kubernetes_version" {
  type = string
  default = "1.25.11"
}

variable "subnet_id" {
  type = string
}

variable "mgmt_cidrs" {
  type = list(string)
}

variable "application_gateway_id" {
  type = string
}

variable "outbound_type" {
  validation {
    condition     = can(regex("^(userAssignedNATGateway|userDefinedRouting)$", var.outbound_type))
    error_message = "Wrong value"
  }
}

variable "node_count" {
  default = 2
}