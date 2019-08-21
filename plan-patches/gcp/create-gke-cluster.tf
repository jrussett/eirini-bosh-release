# K8s Cluster {
resource "google_container_cluster" "gke-cluster" {
  name               = "${var.env_id}-cluster"
  zone               = "${var.zone}"
  network            = "${google_compute_network.bbl-network.name}"
  subnetwork         = "${google_compute_subnetwork.bbl-subnet.name}"
  initial_node_count = "${var.gke_cluster_num_nodes}"

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    machine_type = "${var.gke_cluster_node_machine_type}"

    tags = ["${var.env_id}-cluster-nodes"]
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}

data "google_client_config" "current" {}

provider "kubernetes" {
  host = "${google_container_cluster.gke-cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.gke-cluster.master_auth.0.cluster_ca_certificate)}"
  token = "${data.google_client_config.current.access_token}"
}

resource "kubernetes_namespace" "cf-system" {
  metadata {
    name = "cf-system"
  }
}

resource "kubernetes_service_account" "opi-service-account" {
  metadata {
    name = "opi-service-account"
    namespace = "${kubernetes_namespace.cf-system.id}"
  }
}

resource "kubernetes_cluster_role_binding" "opi-service-account-cluster-role-binding" {
  metadata {
    name = "opi-service-account-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "opi-service-account"
    namespace = "${kubernetes_namespace.cf-system.id}"
  }
}
# }

# Firewall rules {
resource "google_compute_firewall" "gke-nodes-to-opi-vm" {
  name    = "${var.env_id}-gke-nodes-to-opi-vm"
  network = "${google_compute_network.bbl-network.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_tags = ["${var.env_id}-cluster-nodes"]
  target_tags = ["cf-opi"]
}

resource "google_compute_firewall" "gke-nodes-and-pods-to-doppler-vm" {
  name    = "${var.env_id}-gke-nodes-and-pods-to-doppler-vm"
  network = "${google_compute_network.bbl-network.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8082"]
  }

  source_tags   = ["${var.env_id}-cluster-nodes"]
  source_ranges = ["${google_container_cluster.gke-cluster.cluster_ipv4_cidr}"]
  target_tags   = ["cf-doppler"]
}
# }

output "k8s_host_url" {
  value = "${google_container_cluster.gke-cluster.endpoint}"
}

output "k8s_service_username" {
  value = "opi-service-account"
}

output "k8s_service_token" {
  value = "${kubernetes_service_account.opi-service-account.default_secret_name}"
}

output "k8s_ca" {
  value = "${base64decode(google_container_cluster.gke-cluster.master_auth.0.cluster_ca_certificate)}"
}
