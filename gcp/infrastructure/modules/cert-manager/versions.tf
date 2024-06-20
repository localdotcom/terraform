terraform {
  required_version = ">= 1.1.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.49.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.49.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}
