data "terraform_remote_state" "vpc" {
  backend = "gcs"

  config = {
    bucket = var.backend
    prefix = "${var.environment}/vpc"
  }
}

data "terraform_remote_state" "ingress_nginx" {
  backend = "gcs"

  config = {
    bucket = var.backend
    prefix = "${var.environment}/ingress-nginx"
  }
}

data "external" "google_compute_firewall" {
  program = ["../../scripts/get-target-tag"]

  query = {
    project = var.project,
    fw_rule = "k8s-fw-${data.terraform_remote_state.ingress_nginx.outputs.lb_name}"
  }
}
