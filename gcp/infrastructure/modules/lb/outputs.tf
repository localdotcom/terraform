output "firewall_rule" {
  value = google_compute_firewall.allow_lb_external_ips.name
}

output "firewall_rule_target_tag" {
  value = data.external.google_compute_firewall.result.target_tag
}
