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

# ingress-nginx
variable "ingress_nginx" {
  type = object({
    ingress_version = string
    proxy_cache     = bool
    ingress_replicas = map(
      object({
        replica_count = number
      })
    )
  })
}
