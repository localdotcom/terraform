resource "google_storage_bucket" "backend" {
  project       = var.backend.backend_project
  name          = "${var.project}-tfstate"
  force_destroy = true
  location      = "EU"
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }
}
