data "google_project" "current" {}

resource "google_project_service" "compute_engine" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute_engine]
}

# Cloud Router
resource "google_compute_router" "router" {
  name    = "${var.project_id}-router"
  region  = var.region
  network = google_compute_network.vpc_network.name
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_id}-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Subnetwork for GKE (with secondary IP ranges for pods and services)
resource "google_compute_subnetwork" "gke_subnetwork" {
  name          = "${var.project_id}-gke-subnet"
  ip_cidr_range = var.gke_subnetwork_cidr_range
  region        = var.region
  network       = google_compute_network.vpc_network.name

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr_range
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr_range
  }
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_id}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_project_service" "servicenetworking_api" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on              = [google_project_service.servicenetworking_api]
}

resource "google_project_service" "redis_googleapis_com_api" {
  service            = "redis.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_googleapis_com" {
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager_googleapis_com" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

#Enable builds
resource "google_project_service" "cloudbuild_googleapi_com" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
  depends_on         = [google_artifact_registry_repository.docker_repo]
}

# Enabe Vulnerability scanning
resource "google_project_service" "container_scanning_api" {
  service            = "containerscanning.googleapis.com"
  disable_on_destroy = false
  depends_on         = [google_artifact_registry_repository.docker_repo]
}

# Enabe Cloud Deploy
resource "google_project_service" "clouddeploy_googleapis_com" {
  service = "clouddeploy.googleapis.com"
}

# Enabe Binary Authorization API
resource "google_project_service" "binaryauthorization_googleapis_com" {
  service = "binaryauthorization.googleapis.com"
}
