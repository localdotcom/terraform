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

# vpc
variable "vpc" {
  type = object({
    networks = map(
      object({
        subnet_cidr_range                      = string
        cluster_cidr_range                     = string
        services_cidr_range                    = string
        delete_default_internet_gateway_routes = bool
        routes                                 = list(map(string))
      })
    )
    external_ips = object({
      global = bool
      names  = list(string)
    })
  })
}
