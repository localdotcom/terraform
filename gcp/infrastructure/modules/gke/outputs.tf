output "name" {
  value = module.gke.name
}

output "location" {
  value = module.gke.location
}

output "endpoint" {
  value     = module.gke.endpoint
  sensitive = true
}

output "ca_certificate" {
  value     = module.gke.ca_certificate
  sensitive = true
}

output "service_account" {
  value = module.gke.service_account
}

output "identity_namespace" {
  value = module.gke.identity_namespace
}
