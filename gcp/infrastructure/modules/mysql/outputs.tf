output "instance_first_ip_address" {
  value = module.mysql.instance_first_ip_address
}

output "master_password" {
  value     = module.mysql.generated_user_password
  sensitive = true
}

output "additional_databases" {
  value = length(var.mysql.additional_databases) > 0 ? var.mysql.additional_databases[*].name : null
}

output "additional_users" {
  value     = length(var.mysql.additional_databases) > 0 ? { for index, user in var.mysql.additional_databases : user.name => random_password.additional_passwords[index].result } : null
  sensitive = true
}
