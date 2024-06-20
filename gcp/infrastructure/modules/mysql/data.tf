data "terraform_remote_state" "vpc" {
  backend = "gcs"

  config = {
    bucket = var.backend
    prefix = "${var.environment}/vpc"
  }
}

data "terraform_remote_state" "bastion" {
  backend = "gcs"

  config = {
    bucket = var.backend
    prefix = "${var.environment}/bastion"
  }
}
