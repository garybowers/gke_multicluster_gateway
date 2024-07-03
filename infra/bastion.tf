resource "google_service_account" "bastion" {
  project      = google_project.project.project_id
  account_id   = "bastion-sa"
  display_name = "bastion-sa"
}

resource "google_project_iam_member" "roles_container_clusteradmin" {
  project = google_project.project.project_id
  role    = "roles/container.clusterAdmin"
  member  = google_service_account.bastion.member
}

resource "google_project_iam_member" "roles_container_containeradmin" {
  project = google_project.project.project_id
  role    = "roles/container.admin"
  member  = google_service_account.bastion.member
}

resource "google_project_iam_member" "roles_metricswriter" {
  project = google_project.project.project_id
  role    = "roles/monitoring.metricWriter"
  member  = google_service_account.bastion.member
}

resource "google_project_iam_member" "roles_logswriter" {
  project = google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = google_service_account.bastion.member
}


resource "google_compute_instance" "bastion" {
  project      = google_project.project.project_id
  name         = "bastion"
  machine_type = "e2-standard-4"
  zone         = "europe-west1-b"

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.subnet["europe-west1"].self_link
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_vtpm                 = true
  }

  metadata_startup_script = <<EOF
cd /tmp
apt update -y
apt install -y google-osconfig-agent google-cloud-cli-gke-gcloud-auth-plugin kubectl curl git jq nano vim wget tmux
curl -fsSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install
rm add-google-cloud-ops-agent-repo.sh
curl -fsSLO https://github.com/argoproj/argo-cd/releases/download/v2.10.12/argocd-linux-amd64
install -m 755 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
curl -fsSLO https://get.helm.sh/helm-v3.15.2-linux-amd64.tar.gz
tar -xvf helm-v3.15.2-linux-amd64.tar.gz --strip-components=1 --totals linux-amd64/helm
install -m 755 helm /usr/local/bin/helm
rm helm
EOF

  metadata = {
    block-project-ssh-keys = true
  }

  lifecycle {
    ignore_changes = [
      metadata,
      metadata_startup_script
    ]
  }
}