provider "google" {
  project = var.project
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${data.terraform_remote_state.gke.outputs.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.ca_certificate)
}

provider "kubectl" {
  host                   = "https://${data.terraform_remote_state.gke.outputs.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.ca_certificate)
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.terraform_remote_state.gke.outputs.endpoint}"
    token                  = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.ca_certificate)
  }
}

terraform {
  backend "gcs" {}
}
