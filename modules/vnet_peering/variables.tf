variable "on_local" {
  type = object({
    resource_group_name  = string
    virtual_network_name = string
    virtual_network_id   = string
    
    allow_virtual_network_access = optional(bool)
    allow_forwarded_traffic      = optional(bool)
    allow_gateway_transit        = optional(bool)
    use_remote_gateways          = optional(bool)
  })
}

variable "on_remote" {
  type = object({
    resource_group_name  = string
    virtual_network_name = string
    virtual_network_id   = string

    allow_virtual_network_access = optional(bool)
    allow_forwarded_traffic      = optional(bool)
    allow_gateway_transit        = optional(bool)
    use_remote_gateways          = optional(bool)
  })
}