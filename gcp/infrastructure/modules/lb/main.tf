locals {
  name = strcontains(var.project, "-${var.environment}") ? var.project : "${var.project}-${var.environment}"
}

# create a firewall rule to allow LoadBalancer's external IPs access
# this rule will ovverride automatically created firewall rule (https://cloud.google.com/kubernetes-engine/docs/concepts/firewall-rules#service-fws)
resource "google_compute_firewall" "allow_lb_external_ips" {
  project       = var.project
  name          = "allow-lb-external-ips-${var.environment}"
  network       = local.name
  description   = "A firewall rule to allow LoadBalancer's external IPs access"
  priority      = 1000
  direction     = "INGRESS"
  disabled      = false
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [data.external.google_compute_firewall.result.target_tag]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  depends_on = [data.external.google_compute_firewall]
}

# create forwarding rules based on external IP names
resource "google_compute_forwarding_rule" "lb_forwarding_rules" {
  for_each = { for name, address in data.terraform_remote_state.vpc.outputs.external_ip_addresses : name => address if name != data.terraform_remote_state.vpc.outputs.load_balancer_ip_address.name && address != data.terraform_remote_state.vpc.outputs.load_balancer_ip_address.address }

  name        = "${local.name}-${each.key}-forwarding-rule"
  description = "{\"kubernetes.io/service-name\":\"ingress-nginx/ingress-nginx-controller\"}"
  target      = data.terraform_remote_state.ingress_nginx.outputs.lb_self_link
  port_range  = "80-443"
  region      = var.region
  ip_address  = each.value
}
