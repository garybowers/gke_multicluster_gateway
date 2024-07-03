resource "google_dns_managed_zone" "dns" {
  project     = google_project.project.project_id
  name        = "demo-zone"
  dns_name    = "mc.${var.parent_domain}."
  description = "DNS Zone"
}
