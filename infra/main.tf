resource "google_folder" "folder" {
  display_name = "gke-gateway-demo"
  parent       = var.parent_folder
}

resource "random_integer" "salt" {
  min = 100000
  max = 999999
}

resource "google_project" "project" {
  name                = "gke-gateway-demo"
  project_id          = "gke-gateway-demo-${random_integer.salt.result}"
  folder_id           = google_folder.folder.name
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_compute_project_metadata" "oslogin" {
  project = google_project.project.project_id
  metadata = {
    enable-oslogin = "TRUE"
  }
  lifecycle {
    ignore_changes = [
      metadata
    ]
  }
}
