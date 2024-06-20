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

# gke
variable "gke" {
  type = object({
    clusters = map(
      object({
        version                       = string
        release_channel               = string
        regional                      = bool
        create_service_account        = optional(bool)
        override_service_account_name = optional(bool)

      })
    )
    node_pools = map(
      object({
        version                      = string
        auto_upgrade                 = bool
        node_pool_machine_type       = string
        node_pool_disk_size_gb       = number
        node_pool_disk_type          = string
        node_pool_initial_node_count = number
        node_pool_min_count          = number
        node_pool_max_count          = number
        tags                         = list(string)
      })
    )
    addons_config = map(
      object({
        service_external_ips       = bool
        horizontal_pod_autoscaling = bool
      })
    )
    backup_plans = map(
      object({
        enable_backup       = bool
        location            = string
        retain_days         = number
        delete_lock_days    = number
        cron_schedule       = string
        paused              = bool
        include_volume_data = bool
        include_secrets     = bool
        all_namespaces      = bool
      })
    )
  })
}
