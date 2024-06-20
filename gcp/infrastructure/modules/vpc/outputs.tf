# common
output "project" {
  value = var.project
}

output "region" {
  value = var.region
}

output "environment" {
  value = var.environment
}

output "backend" {
  value = var.backend
}

# vpc
output "network_name" {
  value = module.vpc.network_name
}

output "subnet_name" {
  value = "${local.name}-subnet"
}

output "network_self_link" {
  value = module.vpc.network_self_link
}

output "subnet_cidr_range" {
  value = var.vpc.networks[var.environment].subnet_cidr_range
}

output "cluster_cidr_range" {
  value = var.vpc.networks[var.environment].cluster_cidr_range
}

output "services_cidr_range" {
  value = var.vpc.networks[var.environment].services_cidr_range
}

output "pods_range_name" {
  value = "${local.name}-pods"
}

output "services_range_name" {
  value = "${local.name}-services"
}

output "routes" {
  value = var.vpc.networks[var.environment].routes
}

output "peering_network_name" {
  value = google_compute_global_address.peering.name
}

output "deployment_zone" {
  value = random_shuffle.zone.result[0]
}

output "nat_ip_address" {
  value = google_compute_address.nat_ip.address
}

output "load_balancer_ip_address" {
  value = length(google_compute_address.external_ips) > 0 ? {
    name    = values(google_compute_address.external_ips)[0].name
    address = values(google_compute_address.external_ips)[0].address
  } : null
}

output "external_ip_addresses" {
  value = length(google_compute_address.external_ips) > 0 ? { for external_ip in google_compute_address.external_ips : external_ip.name => external_ip.address } : (
    length(google_compute_global_address.external_ips) > 0 ? { for external_ip in google_compute_global_address.external_ips : external_ip.name => external_ip.address } : null
  )
}
