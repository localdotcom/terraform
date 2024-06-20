# common
variable "project" {
  default = ""
}

variable "region" {
  default = ""
}

variable "environment" {
  default = ""
}

variable "backend" {
  default = ""
}

# cert-manager
variable "cert_manager" {
  type = object({
    cert_manager_version = string
  })
}
