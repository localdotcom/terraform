output "instance_first_ip_address" {
  value = module.postgresql.instance_first_ip_address
}

output "master_password" {
  value     = module.postgresql.generated_user_password
  sensitive = true
}

output "additional_databases" {
  value = length(var.postgresql.additional_databases) > 0 ? var.postgresql.additional_databases[*].name : null
}

output "additional_users" {
  value     = length(var.postgresql.additional_databases) > 0 ? { for index, user in var.postgresql.additional_databases : user.name => random_password.additional_passwords[index].result } : null
  sensitive = true
}

