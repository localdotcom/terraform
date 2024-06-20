provider "google" {
  project = var.project
  region  = var.region
}

provider "postgresql" {
  alias             = "tunnel"
  host              = module.db_tunnel.host
  port              = module.db_tunnel.port
  username          = "root"
  password          = module.postgresql.generated_user_password
  database_username = "postgres"
  superuser         = false
}

terraform {
  backend "gcs" {}
}

