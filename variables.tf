variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the GKE master"
  default     = "172.16.0.0/28"
}

variable "gke_subnetwork_cidr_range" {
  type        = string
  description = "The primary IP range for the GKE subnetwork in CIDR notation"
  default     = "10.1.0.0/16"
}

variable "pods_cidr_range" {
  type        = string
  description = "The secondary IP range for pods in CIDR notation"
  default     = "10.2.0.0/16"
}

variable "services_cidr_range" {
  type        = string
  description = "The secondary IP range for services in CIDR notation"
  default     = "10.3.0.0/16"
}

