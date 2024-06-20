locals {
  service_accounts_list = can(var.iam.service_accounts[var.project]) ? [
    for service_account in var.iam.service_accounts[var.project] : {
      name         = service_account.name
      create       = service_account.create
      display_name = service_account.display_name
    }
  ] : []

  service_account_role_bindings = can(var.iam.service_accounts[var.project]) ? flatten([
    for service_account in var.iam.service_accounts[var.project] : [
      for role in service_account.roles != null ? service_account.roles : [] : [
        {
          name            = service_account.name
          grant_access_to = service_account.grant_access_to
          member          = "serviceAccount:${service_account.name}@${coalesce(service_account.parent_project, var.project)}.iam.gserviceaccount.com"
          role            = role
        }
      ]
    ]
  ]) : []

  user_role_bindings = can(var.iam.users[var.project]) ? flatten([
    for user in var.iam.users[var.project] : [
      for role in user.roles : {
        member = "user:${user.name}"
        role   = role
      }
    ]
  ]) : []
}

# create service account
resource "google_service_account" "this" {
  for_each = { for idx, combination in local.service_accounts_list : idx => combination if combination.create == true }

  project      = var.project
  account_id   = each.value.name
  display_name = each.value.display_name
}

# grant service accounts access to the projects
resource "google_project_iam_member" "service_accounts" {
  for_each = { for idx, combination in local.service_account_role_bindings : idx => combination if combination.grant_access_to == "project" }

  project = var.project
  role    = each.value.role
  member  = each.value.member

  depends_on = [
    google_service_account.this,
    google_project_iam_custom_role.custom_roles
  ]
}

# grant users access to the project
resource "google_project_iam_member" "users" {
  for_each = { for idx, combination in local.user_role_bindings : idx => combination }

  project = var.project
  role    = each.value.role
  member  = each.value.member

  depends_on = [
    google_project_iam_custom_role.custom_roles
  ]
}

# create custom roles
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = var.iam.custom_roles != null ? { for role in var.iam.custom_roles : role.role_id => role } : {}

  project     = var.project
  role_id     = each.value.role_id
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
}
