locals {
  name           = strcontains(var.project, "-${var.environment}") ? var.project : "${var.project}-${var.environment}"
  pods_range     = data.terraform_remote_state.vpc.outputs.pods_range_name
  services_range = data.terraform_remote_state.vpc.outputs.services_range_name
  network        = data.terraform_remote_state.vpc.outputs.network_name
  subnet         = data.terraform_remote_state.vpc.outputs.subnet_name
  zone           = data.terraform_remote_state.vpc.outputs.deployment_zone
}

# https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/v28.0.0/modules/beta-private-cluster
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version = "${TF_MODULE_VERSION}"

  name                       = local.name
  project_id                 = var.project
  region                     = var.region
  kubernetes_version         = var.gke.clusters[var.environment].version
  release_channel            = var.gke.clusters[var.environment].release_channel
  regional                   = var.gke.clusters[var.environment].regional
  create_service_account     = coalesce(var.gke.clusters[var.environment].create_service_account, true)
  service_account_name       = var.gke.clusters[var.environment].override_service_account_name == true ? "gke-${local.name}" : ""
  enable_private_endpoint    = false
  enable_private_nodes       = true
  filestore_csi_driver       = false
  gke_backup_agent_config    = var.gke.backup_plans[var.environment].enable_backup
  grant_registry_access      = true
  horizontal_pod_autoscaling = var.gke.addons_config[var.environment].horizontal_pod_autoscaling
  http_load_balancing        = true
  identity_namespace         = "enabled"
  initial_node_count         = 0
  ip_range_pods              = local.pods_range
  ip_range_services          = local.services_range
  network                    = local.network
  network_policy             = false
  remove_default_node_pool   = true
  service_external_ips       = var.gke.addons_config[var.environment].service_external_ips
  subnetwork                 = local.subnet
  zones                      = var.gke.clusters[var.environment].regional ? [] : [local.zone]

  node_pools = [
    {
      name               = "${local.name}-node-pool"
      version            = var.gke.node_pools[var.environment].version
      auto_upgrade       = var.gke.node_pools[var.environment].auto_upgrade
      auto_repair        = true
      enable_secure_boot = true
      disk_size_gb       = var.gke.node_pools[var.environment].node_pool_disk_size_gb
      disk_type          = var.gke.node_pools[var.environment].node_pool_disk_type
      enable_gcfs        = false
      image_type         = "COS_CONTAINERD"
      initial_node_count = var.gke.node_pools[var.environment].node_pool_initial_node_count
      local_ssd_count    = 0
      machine_type       = var.gke.node_pools[var.environment].node_pool_machine_type
      max_count          = var.gke.node_pools[var.environment].node_pool_max_count
      min_count          = var.gke.node_pools[var.environment].node_pool_min_count
      node_locations     = var.gke.clusters[var.environment].regional ? "" : local.zone
      preemptible        = false
    }
  ]

  node_pools_tags = {
    all = var.gke.node_pools[var.environment].tags
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_backup_backup_plan
resource "google_gke_backup_backup_plan" "this" {
  count = var.gke.backup_plans[var.environment].enable_backup ? 1 : 0

  name     = "${local.name}-backup"
  cluster  = module.gke.cluster_id
  location = var.gke.backup_plans[var.environment].location

  retention_policy {
    backup_delete_lock_days = var.gke.backup_plans[var.environment].delete_lock_days
    backup_retain_days      = var.gke.backup_plans[var.environment].retain_days
  }

  backup_schedule {
    cron_schedule = var.gke.backup_plans[var.environment].cron_schedule
    paused        = var.gke.backup_plans[var.environment].paused
  }

  backup_config {
    include_volume_data = var.gke.backup_plans[var.environment].include_volume_data
    include_secrets     = var.gke.backup_plans[var.environment].include_secrets
    all_namespaces      = var.gke.backup_plans[var.environment].all_namespaces
  }
}
