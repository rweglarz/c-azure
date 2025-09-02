variable "on_local" {
  type = object({
    resource_group_name  = string
    virtual_network_name = string
    virtual_network_id   = string
    
    allow_virtual_network_access = optional(bool)
    allow_forwarded_traffic      = optional(bool)
    allow_gateway_transit        = optional(bool)
    use_remote_gateways          = optional(bool)
    subnet_names                 = optional(list(string))
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
    subnet_names                 = optional(list(string))
  })
  validation {
    condition     = (var.on_local.subnet_names==null && var.on_remote.subnet_names==null) || (length(var.on_local.subnet_names)>0 && length(var.on_remote.subnet_names)>0 )
    error_message = "Both local and remote subnet names must be provided"
  }
}
