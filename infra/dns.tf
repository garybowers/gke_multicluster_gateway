resource "google_dns_managed_zone" "dns" {
  project     = google_project.project.project_id
  name        = "demo-zone"
  dns_name    = "mc.${var.parent_domain}."
  description = "DNS Zone"
}

resource "google_dns_record_set" "site-bowers1" {
  project = google_project.project.project_id
  name    = google_dns_managed_zone.dns.dns_name
  type    = "A"
  ttl     = 60

  managed_zone = google_dns_managed_zone.dns.name

  rrdatas = [google_compute_global_address.gke_gw_address.address]
}

resource "google_dns_record_set" "site-bowers1-all" {
  project = google_project.project.project_id
  name    = "*.${google_dns_managed_zone.dns.dns_name}"
  type    = "A"
  ttl     = 60

  managed_zone = google_dns_managed_zone.dns.name

  rrdatas = [google_compute_global_address.gke_gw_address.address]
}

