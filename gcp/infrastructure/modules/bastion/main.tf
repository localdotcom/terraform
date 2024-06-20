locals {
  name    = strcontains(var.project, "-${var.environment}") ? var.project : "${var.project}-${var.environment}"
  network = data.terraform_remote_state.vpc.outputs.network_self_link
  subnet  = data.terraform_remote_state.vpc.outputs.subnet_name
  zone    = data.terraform_remote_state.vpc.outputs.deployment_zone
}

# https://github.com/terraform-google-modules/terraform-google-bastion-host
module "iap_bastion" {
  source  = "terraform-google-modules/bastion-host/google"
  version = "${TF_MODULE_VERSION}"

  name                 = "${local.name}-bastion"
  project              = var.project
  zone                 = local.zone
  network              = local.network
  subnet               = local.subnet
  shielded_vm          = true
  create_firewall_rule = false
  machine_type         = var.bastion.machine_type
  disk_type            = var.bastion.disk_type
  disk_size_gb         = var.bastion.disk_size_gb
  service_account_name = "bastion-${var.environment}"
  startup_script       = var.startup_script
  tags                 = var.bastion.tags
}
