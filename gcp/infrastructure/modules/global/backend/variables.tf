# common
variable "project" {
  default = ""
}

variable "region" {
  default = ""
}

# backend
variable "backend" {
  type = object({
    backend_project = string
    backend_bucket  = string
  })
}
