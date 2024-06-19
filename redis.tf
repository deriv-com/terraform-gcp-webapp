variable "redis_enabled" {
  type        = bool
  description = "Add a Redis for the setup or not"
  default     = false
}

variable "redis_tier" {
  type        = string
  description = "BASIC, STANDARD_HA"
  default     = "BASIC"
}

# https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances
variable "redis_version" {
  type        = string
  description = "Redis version e.g REDIS_7_0"
  default     = ""
}

variable "redis_memory_size_gb" {
  type        = number
  description = "The memory size in GB for the Redis instance"
  default     = 1
}


# Cloud Memorystore Redis
resource "google_redis_instance" "redis_instance" {
  count              = var.redis_enabled ? 1 : 0
  name               = "${var.project_id}-redis"
  tier               = var.redis_tier
  memory_size_gb     = var.redis_memory_size_gb
  redis_version      = var.redis_version
  region             = var.region
  authorized_network = google_compute_network.vpc_network.id
  depends_on         = [google_project_service.redis_googleapis_com_api]
}

output "redis_host" {
  value = google_redis_instance.redis_instance[*].host
}
output "redis_port" {
  value = google_redis_instance.redis_instance[*].port
}
