output "lb_name" {
  value = data.external.google_compute_target_pool.result.name
}

output "lb_self_link" {
  value = data.external.google_compute_target_pool.result.self_link
}
