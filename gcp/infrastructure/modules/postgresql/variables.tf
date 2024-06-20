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

# postgresql
variable "postgresql" {
  type = object({
    db_version = string
    db_tiers = map(
      object({
        db_tier = string
      })
    )
    insights_config = map(
      object({
        query_plans_per_minute  = number
        query_string_length     = number
        record_application_tags = bool
        record_client_address   = bool
      })
    )
    role_permissions = object({
      create_database  = bool
      create_role      = bool
      additional_roles = list(string)
    })
    additional_databases = list(map(string))
    db_flags             = list(map(string))
  })
}
