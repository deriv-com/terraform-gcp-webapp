variable "postgres_enabled" {
  type        = bool
  description = "Add a Cloud SQL for the setup or not"
  default     = false
}


# https://cloud.google.com/sql/pricing
variable "postgres_tier" {
  type        = string
  description = "The tier (machine type) for the PostgreSQL instance (e.g., 'db-f1-micro')"
  default     = "db-f1-micro"
}

# https://cloud.google.com/sql/docs/editions-intro
variable "postgres_edition" {
  type        = string
  description = "The edition of the instance, can be ENTERPRISE or ENTERPRISE_PLUS"
  default     = "ENTERPRISE"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#database_version
variable "postgres_version" {
  type        = string
  description = "The MySQL, PostgreSQL or SQL Server version to use."
  default     = "POSTGRES_14"
}

variable "postgres_disk_size_gb" {
  type        = number
  description = "The disk size in GB"
  default     = 10
}


resource "google_sql_database_instance" "postgres_instance" {
  count               = var.postgres_enabled ? 1 : 0
  name                = "${var.project_id}-pg"
  database_version    = var.postgres_version
  region              = var.region
  deletion_protection = false


  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier                        = var.postgres_tier
    edition                     = var.postgres_edition
    deletion_protection_enabled = true
    disk_size                   = var.postgres_disk_size_gb
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc_network.id
      enable_private_path_for_google_cloud_services = true

    }
  }
}

output "postgres_host" {
  value = google_sql_database_instance.postgres_instance[*].private_ip_address
}
