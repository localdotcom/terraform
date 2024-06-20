provider "google" {
  project = var.project
  region  = var.region
}

provider "mysql" {
  alias    = "tunnel"
  endpoint = "${module.db_tunnel.host}:${module.db_tunnel.port}"
  username = "root"
  password = module.mysql.generated_user_password
}

terraform {
  backend "gcs" {}
}
