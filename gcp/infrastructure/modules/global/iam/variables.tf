# common
variable "project" {
  default = ""
}

variable "region" {
  default = ""
}

# iam
variable "iam" {
  type = object({
    service_accounts = map(list(object({
      name            = string
      create          = optional(bool)
      display_name    = optional(string)
      parent_project  = optional(string)
      grant_access_to = optional(string)
      roles           = optional(list(string))
    })))
    users = map(list(object({
      name  = string
      roles = list(string)
    })))
    custom_roles = optional(list(object({
      role_id     = string
      title       = string
      description = string
      permissions = list(string)
    })))
  })
}
