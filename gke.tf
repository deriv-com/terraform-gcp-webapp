variable "image_repo" {
  type        = string
  description = "GCP Artifact repository to store container images"
  default     = "app"
}

# https://cloud.google.com/compute/vm-instance-pricing
variable "gke_machine_type" {
  type        = string
  description = "Nodepool node type"
  default     = "e2-medium"
}

variable "gke_max_node_count" {
  type        = number
  description = "Maximum number of nodes per zone in the NodePool."
  default     = 2
}

variable "authorized_cidr_blocks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
}

# GKE Cluster (with private nodes and ingress enabled)
resource "google_container_cluster" "gke_cluster" {
  provider            = google-beta
  name                = "${var.project_id}-gke"
  location            = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_cidr_blocks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
    gcp_public_cidrs_access_enabled = true
  }

  # Private Cluster Configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # https://cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component
  secret_manager_config {
    enabled = true
  }

  # Workload Identity allows Kubernetes service accounts to act as a user-managed Google IAM Service Account.
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # IP Allocation Policy (for private IPs)
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.gke_subnetwork.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke_subnetwork.secondary_ip_range[1].range_name
  }

  # Ingress Configuration
  addons_config {
    http_load_balancing {
      disabled = true
    }
    istio_config {
      disabled = false
    }

  }


  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  protect_config {
    workload_vulnerability_mode = "BASIC"
  }

  # https://cloud.google.com/binary-authorization/docs/getting-started-cli#view_the_default_policy
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  network    = google_compute_network.vpc_network.id
  subnetwork = google_compute_subnetwork.gke_subnetwork.name
}

resource "google_project_iam_member" "secret_access_for_gke_sa" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "principal://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/default"
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.project_id}-gke-primary"
  location = var.region
  cluster  = google_container_cluster.gke_cluster.name

  depends_on = [google_container_cluster.gke_cluster]

  autoscaling {
    min_node_count = 1
    max_node_count = var.gke_max_node_count
  }

  node_config {
    machine_type = var.gke_machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = var.image_repo
  format        = "DOCKER"
  depends_on    = [google_project_service.artifactregistry]
  docker_config {
    immutable_tags = true
  }
}
