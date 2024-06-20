# common
variable "org_name" {
  default = ""
}

variable "project" {
  default = ""
}

variable "region" {
  default = ""
}

# project
variable "project_settings" {
  type = object({
    organizations = map(object({
      org_id          = string
      billing_account = string
    }))
    api_services = list(string)
    metadata     = list(map(string))
  })
}
