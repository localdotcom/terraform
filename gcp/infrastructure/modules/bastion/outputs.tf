output "bastion_hostname" {
  value = module.iap_bastion.hostname
}

output "bastion_gcp_zone" {
  value = local.zone
}
