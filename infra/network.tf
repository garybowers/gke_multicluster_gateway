resource "google_compute_network" "vpc" {
  name                    = "demo-vpc"
  project                 = google_project.project.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "subnet" {
  for_each = { for region in var.regions : region.region => region }
  project  = google_project.project.project_id
  region   = each.value["region"]
  name     = "demo-subnet"
  network  = google_compute_network.vpc.self_link

  private_ip_google_access = true

  ip_cidr_range = lookup(each.value, "ip_cidr", "10.0.0.0/16")
  secondary_ip_range = [
    {
      range_name    = "pod-range"
      ip_cidr_range = lookup(each.value, "ip_cidr_pods", "")
    },
    {
      range_name    = "service-range"
      ip_cidr_range = lookup(each.value, "ip_cidr_services", "")
    },
  ]
}

resource "google_compute_router" "nat_router" {
  for_each = { for region in var.regions : region.region => region }

  project = google_project.project.project_id
  name    = "demo-nat-rtr"

  region  = each.value["region"]
  network = google_compute_network.vpc.self_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_address" "nat_gw_address" {
  for_each = { for region in var.regions : region.region => region }
  project  = google_project.project.project_id
  name     = "nat-ext-addr"
  region   = each.value["region"]
}

resource "google_compute_router_nat" "nat" {
  for_each = { for region in var.regions : region.region => region }
  project  = google_project.project.project_id
  name     = "nat-ext-addr"
  region   = each.value["region"]
  router   = google_compute_router.nat_router[each.key].name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.nat_gw_address[each.key].*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.subnet[each.key].self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

}

resource "google_compute_firewall" "ingress_allow_iap" {
  project = google_project.project.project_id
  name    = "ingress-allow-iap"
  network = google_compute_network.vpc.name

  priority = 200

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_global_address" "gke_gw_address" {
  project = google_project.project.project_id
  name    = "gateway-1-ext-addr"
}
