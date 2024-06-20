locals {
  name             = strcontains(var.project, "-${var.environment}") ? var.project : "${var.project}-${var.environment}"
  zone             = data.terraform_remote_state.vpc.outputs.deployment_zone
  peering_network  = data.terraform_remote_state.vpc.outputs.peering_network_name
  private_network  = data.terraform_remote_state.vpc.outputs.network_self_link
  bastion_hostname = data.terraform_remote_state.bastion.outputs.bastion_hostname
  bastion_zone     = data.terraform_remote_state.bastion.outputs.bastion_gcp_zone
}

# https://registry.terraform.io/modules/GoogleCloudPlatform/sql-db/google/11.0.0/submodules/postgresql
module "postgresql" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "${TF_MODULE_VERSION}"

  project_id = var.project
  region     = var.region
  zone       = local.zone

  name                            = local.name
  availability_type               = !strcontains(var.environment, "prod") ? "ZONAL" : "REGIONAL"
  database_version                = var.postgresql.db_version
  deletion_protection             = false
  disk_autoresize                 = true
  user_name                       = "root"
  disk_autoresize_limit           = !strcontains(var.environment, "prod") ? 100 : 500
  disk_size                       = !strcontains(var.environment, "prod") ? 20 : 100
  disk_type                       = "PD_SSD"
  maintenance_window_day          = "6"
  maintenance_window_hour         = "6"
  maintenance_window_update_track = "stable"
  tier                            = var.postgresql.db_tiers[var.environment].db_tier
  create_timeout                  = "1h"
  update_timeout                  = "1h"
  delete_timeout                  = "1h"

  additional_databases = var.postgresql.additional_databases

  database_flags = var.postgresql.db_flags

  insights_config = {
    query_plans_per_minute  = var.postgresql.insights_config[var.environment].query_plans_per_minute
    query_string_length     = var.postgresql.insights_config[var.environment].query_string_length
    record_application_tags = var.postgresql.insights_config[var.environment].record_application_tags
    record_client_address   = var.postgresql.insights_config[var.environment].record_client_address
  }

  ip_configuration = {
    allocated_ip_range  = local.peering_network
    authorized_networks = []
    ipv4_enabled        = false
    private_network     = local.private_network
    require_ssl         = false
  }

  backup_configuration = {
    enabled                        = true
    start_time                     = !strcontains(var.environment, "prod") ? "02:00" : "04:00"
    location                       = null
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = "7"
    retained_backups               = !strcontains(var.environment, "prod") ? "7" : "14"
    retention_unit                 = "COUNT"
  }
}

resource "random_password" "additional_passwords" {
  count = length(var.postgresql.additional_databases)

  special = false
  length  = 32
}

# forked version based on https://github.com/flaupretre/terraform-ssh-tunnel
module "db_tunnel" {
  source = "git::https://github.com/localdotcom/terraform-ssh-tunnel.git?ref=iap-tunnel"

  create             = length(var.postgresql.additional_databases) > 0 ? true : false
  type               = "iap"
  ssh_cmd            = "gcloud"
  iap_gcp_project    = var.project
  iap_gcp_zone       = local.bastion_zone
  target_host        = module.postgresql.instance_first_ip_address
  target_port        = 5432
  gateway_host       = local.bastion_hostname
  parent_wait_sleep  = "30"
  tunnel_check_sleep = "60"
}

# https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_role
resource "postgresql_role" "additional_users" {
  provider = postgresql.tunnel
  for_each = zipmap(var.postgresql.additional_databases[*].name, random_password.additional_passwords[*].result)

  name                = each.key
  password            = each.value
  login               = true
  create_database     = var.postgresql.role_permissions.create_database
  create_role         = var.postgresql.role_permissions.create_role
  skip_reassign_owned = true

  roles = var.postgresql.role_permissions.additional_roles

  lifecycle {
    ignore_changes = [
      password
    ]
  }

  depends_on = [
    module.postgresql,
    module.db_tunnel # execute 'postgresql.tunnel' provider only when ssh tunnel is up 
  ]
}

# https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_grant
resource "postgresql_grant" "additional_users" {
  provider = postgresql.tunnel
  for_each = { for db in var.postgresql.additional_databases : db.name => db }

  role        = each.value.name
  database    = each.value.name
  object_type = "database"
  privileges  = ["ALL"]

  lifecycle {
    ignore_changes = [
      privileges
    ]
  }

  depends_on = [
    postgresql_role.additional_users
  ]
}
