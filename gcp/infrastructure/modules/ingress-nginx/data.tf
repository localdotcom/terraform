# google_client_config and kubernetes provider must be explicitly specified
data "google_client_config" "provider" {}

data "terraform_remote_state" "vpc" {
  backend = "gcs"

  config = {
    bucket = var.backend
    prefix = "${var.environment}/vpc"
  }
}

data "terraform_remote_state" "gke" {
  backend = "gcs"

  config = {
    bucket = var.backend
    prefix = "${var.environment}/gke"
  }
}

data "external" "google_compute_target_pool" {
  program = ["../../scripts/get-target-pool"]

  query = {
    project     = var.project,
    environment = var.environment
  }

  depends_on = [helm_release.ingress_nginx]
}
