resource "random_id" "postfix" {
  byte_length = 4
}

resource "google_gke_hub_fleet" "fleet" {
  project      = google_project.project.project_id
  display_name = "${google_project.project.project_id}-fleet"

  default_cluster_config {
    security_posture_config {
      mode               = "DISABLED"
      vulnerability_mode = "VULNERABILITY_DISABLED"
    }
  }
}

resource "google_gke_hub_feature" "feature" {
  project  = google_project.project.project_id
  name     = "multiclusterservicediscovery"
  location = "global"
  labels = {
    foo = "bar"
  }
}

/* Create the clusters */
resource "google_service_account" "cluster_sa" {
  for_each     = { for region in var.regions : region.region => region }
  project      = google_project.project.project_id
  account_id   = "cluster-${each.value["region"]}-${random_id.postfix.hex}"
  display_name = "cluster-${each.value["region"]}-${random_id.postfix.hex}"
}


resource "google_container_cluster" "clusters" {
  for_each = { for region in var.regions : region.region => region }
  project  = google_project.project.project_id

  name     = "cluster-${each.value["region"]}"
  location = each.value["region"]

  deletion_protection = false

  network         = google_compute_network.vpc.name
  subnetwork      = google_compute_subnetwork.subnet[each.key].self_link
  networking_mode = "VPC_NATIVE"

  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    service_account = google_service_account.cluster_sa[each.key].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "service-range"
    stack_type                    = "IPV4"
  }

  datapath_provider = "ADVANCED_DATAPATH"

  cost_management_config {
    enabled = true
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = lookup(each.value, "master_ipv4_cidr", "")
    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "all"
    }
  }

  release_channel {
    channel = lookup(each.value, "release_channel", "")
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  workload_identity_config {
    workload_pool = "${google_project.project.project_id}.svc.id.goog"
  }

  fleet {
    project = google_project.project.project_id
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}


resource "google_container_node_pool" "node_pools" {
  for_each = { for region in var.regions : region.region => region }
  project  = google_project.project.project_id
  location = each.value["region"]
  cluster  = google_container_cluster.clusters[each.key].name

  name = "np-${random_id.postfix.hex}"

  node_config {
    image_type   = "COS_CONTAINERD"
    machine_type = "e2-standard-4"
    disk_type    = "pd-balanced"
    disk_size_gb = 100

    service_account = google_service_account.cluster_sa[each.key].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    metadata = {
      "disable-legacy-endpoints" = "true"
    }

    shielded_instance_config {
      enable_secure_boot          = "true"
      enable_integrity_monitoring = "true"
    }


  }

  initial_node_count = 1

  management {
    auto_repair  = true
    auto_upgrade = true
  }

}