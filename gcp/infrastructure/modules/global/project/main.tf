module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "${TF_MODULE_VERSION}"

  name                        = var.project
  org_id                      = var.project_settings.organizations[var.org_name].org_id
  billing_account             = var.project_settings.organizations[var.org_name].billing_account
  auto_create_network         = false
  create_project_sa           = false
  default_service_account     = "delete"
  disable_services_on_destroy = true

  activate_apis = var.project_settings.api_services
}

# add project-level metadata
resource "google_compute_project_metadata_item" "this" {
  for_each = { for metadata in var.project_settings.metadata : metadata.key => metadata }

  project = var.project
  key     = each.key
  value   = each.value.value

  depends_on = [
    module.project
  ]
}
