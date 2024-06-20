locals {
  name = strcontains(var.project, "-${var.environment}") ? var.project : "${var.project}-${var.environment}"
}

# https://github.com/terraform-google-modules/terraform-google-network
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "${TF_MODULE_VERSION}"

  project_id                             = var.project
  delete_default_internet_gateway_routes = var.vpc.networks[var.environment].delete_default_internet_gateway_routes
  network_name                           = local.name
  routing_mode                           = "GLOBAL"

  firewall_rules = [{
    name      = "allow-iap-ssh-ingress-${var.environment}"
    direction = "INGRESS"
    ranges    = ["35.235.240.0/20"]
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
  }]

  subnets = [
    {
      subnet_name           = "${local.name}-subnet"
      subnet_ip             = var.vpc.networks[var.environment].subnet_cidr_range
      subnet_region         = var.region
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    "${local.name}-subnet" = [
      {
        range_name    = "${local.name}-pods"
        ip_cidr_range = var.vpc.networks[var.environment].cluster_cidr_range
      },
      {
        range_name    = "${local.name}-services"
        ip_cidr_range = var.vpc.networks[var.environment].services_cidr_range
      }
    ]
  }

  routes = var.vpc.networks[var.environment].routes
}

# vpc peering to the cloud sql
resource "google_compute_global_address" "peering" {
  name          = "${local.name}-peering"
  project       = var.project
  network       = module.vpc.network_self_link
  prefix_length = 20
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
}

# create a private connection
resource "google_service_networking_connection" "networking_connection" {
  network                 = module.vpc.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.peering.name]
}

# create nat for the private node pool 
resource "google_compute_address" "nat_ip" {
  name = "${local.name}-nat"
}

resource "google_compute_router" "router" {
  name    = "${local.name}-peering"
  project = var.project
  region  = var.region
  network = module.vpc.network_self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.name}-nat"
  project                            = var.project
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.nat_ip.*.self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# provide access to available zones in a region for a given project
data "google_compute_zones" "zones" {
  region = var.region
}

resource "random_shuffle" "zone" {
  input        = data.google_compute_zones.zones.names
  result_count = 1
}

# create regional external static ip addresses
resource "google_compute_address" "external_ips" {
  for_each = !var.vpc.external_ips.global ? toset(var.vpc.external_ips.names) : []

  name         = each.key
  region       = var.region
  address_type = "EXTERNAL"

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}

# create global external static ip addresses
resource "google_compute_global_address" "external_ips" {
  for_each = var.vpc.external_ips.global ? toset(var.vpc.external_ips.names) : []

  name         = each.key
  address_type = "EXTERNAL"

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}
