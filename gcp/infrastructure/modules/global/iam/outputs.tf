output "service_accounts" {
  value = length(google_service_account.this) > 0 ? [
    for service_account in google_service_account.this : {
      "name"  = service_account.account_id
      "email" = service_account.email
      "id"    = service_account.id
    }
  ] : null
}

output "service_account_role_bindings" {
  value = can(var.iam.service_accounts[var.project]) ? [
    for service_account in var.iam.service_accounts[var.project] : {
      member = "serviceAccount:${service_account.name}@${coalesce(service_account.parent_project, var.project)}.iam.gserviceaccount.com"
      roles  = service_account.roles != null ? service_account.roles : []
    }
  ] : null
}

output "user_role_bindings" {
  value = can(var.iam.users[var.project]) ? [
    for user in var.iam.users[var.project] : {
      member = "user:${user.name}"
      role   = user.roles
    }
  ] : null
}

output "custom_roles" {
  value = length(google_project_iam_custom_role.custom_roles) > 0 ? { for id, role in google_project_iam_custom_role.custom_roles : id => role.id } : null
}
