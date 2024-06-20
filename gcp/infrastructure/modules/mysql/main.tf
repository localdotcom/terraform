locals {
  name             = strcontains(var.project, "-${var.environment}") ? var.project : "${var.project}-${var.environment}"
  zone             = data.terraform_remote_state.vpc.outputs.deployment_zone
  peering_network  = data.terraform_remote_state.vpc.outputs.peering_network_name
  private_network  = data.terraform_remote_state.vpc.outputs.network_self_link
  bastion_hostname = data.terraform_remote_state.bastion.outputs.bastion_hostname
  bastion_zone     = data.terraform_remote_state.bastion.outputs.bastion_gcp_zone
}

# https://registry.terraform.io/modules/GoogleCloudPlatform/sql-db/google/11.0.0/submodules/mysql
module "mysql" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version = "${TF_MODULE_VERSION}"

  project_id = var.project
  region     = var.region
  zone       = local.zone

  name                            = local.name
  availability_type               = !strcontains(var.environment, "prod") ? "ZONAL" : "REGIONAL"
  database_version                = var.mysql.db_version
  deletion_protection             = false
  disk_autoresize                 = true
  user_name                       = "root"
  disk_autoresize_limit           = !strcontains(var.environment, "prod") ? 100 : 500
  disk_size                       = !strcontains(var.environment, "prod") ? 20 : 100
  disk_type                       = "PD_SSD"
  maintenance_window_day          = "6"
  maintenance_window_hour         = "6"
  maintenance_window_update_track = "stable"
  tier                            = var.mysql.db_tiers[var.environment].db_tier
  create_timeout                  = "1h"
  update_timeout                  = "1h"
  delete_timeout                  = "1h"

  additional_databases = var.mysql.additional_databases

  database_flags = var.mysql.db_flags

  insights_config = {
    query_plans_per_minute  = var.mysql.insights_config[var.environment].query_plans_per_minute
    query_string_length     = var.mysql.insights_config[var.environment].query_string_length
    record_application_tags = var.mysql.insights_config[var.environment].record_application_tags
    record_client_address   = var.mysql.insights_config[var.environment].record_client_address
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
    binary_log_enabled             = false
    start_time                     = !strcontains(var.environment, "prod") ? "02:00" : "04:00"
    location                       = null
    transaction_log_retention_days = "7"
    retained_backups               = !strcontains(var.environment, "prod") ? "7" : "14"
    retention_unit                 = "COUNT"
  }
}

resource "random_password" "additional_passwords" {
  count = length(var.mysql.additional_databases)

  special = false
  length  = 32
}

# forked version based on https://github.com/flaupretre/terraform-ssh-tunnel
module "db_tunnel" {
  source = "git::https://github.com/localdotcom/terraform-ssh-tunnel.git?ref=iap-tunnel"

  create             = length(var.mysql.additional_databases) > 0 ? true : false
  type               = "iap"
  ssh_cmd            = "gcloud"
  iap_gcp_project    = var.project
  iap_gcp_zone       = local.bastion_zone
  target_host        = module.mysql.instance_first_ip_address
  target_port        = 3306
  gateway_host       = local.bastion_hostname
  parent_wait_sleep  = "30"
  tunnel_check_sleep = "60"
}

# https://registry.terraform.io/providers/winebarrel/mysql/latest/docs/resources/user
resource "mysql_user" "additional_users" {
  provider = mysql.tunnel
  for_each = zipmap(var.mysql.additional_databases[*].name, random_password.additional_passwords[*].result)

  user               = each.key
  plaintext_password = each.value
  host               = "%"

  lifecycle {
    ignore_changes = [
      plaintext_password
    ]
  }

  depends_on = [
    module.mysql
  ]
}

# https://registry.terraform.io/providers/winebarrel/mysql/latest/docs/resources/grant
resource "mysql_grant" "additional_users" {
  provider = mysql.tunnel
  for_each = { for db in var.mysql.additional_databases : db.name => db }

  user       = each.value.name
  database   = each.value.name
  host       = mysql_user.additional_users[each.key].host
  privileges = ["ALL PRIVILEGES"]
  grant      = false

  depends_on = [
    mysql_user.additional_users
  ]
}
