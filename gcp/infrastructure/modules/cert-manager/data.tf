# google_client_config and kubernetes provider must be explicitly specified
data "google_client_config" "provider" {}

data "terraform_remote_state" "gke" {
  backend = "gcs"

  config = {
    bucket = var.backend
    prefix = "${var.environment}/gke"
  }
}
