variable "name" {
}

variable "resource_group_name" {

}

variable "location" {

}

variable "size" {
  default = "Standard_D3_v2"
}

variable "panos" {
  nullable = false
  default  = "10.1.9"
}

variable "username" {
}

variable "password" {
}

variable "interfaces" {

}

variable "bootstrap_options" {

}
