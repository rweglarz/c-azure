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
  default  = "11.1.3"
}

variable "username" {
}

variable "password" {
}

variable "interfaces" {

}

variable "bootstrap_options" {

}

variable "airs" {
  default = false
}
