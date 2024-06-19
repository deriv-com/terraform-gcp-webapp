# terraform-gcp-webapp
This terraform module will provision GKE, DB and Redis components for deployments of simple web apps in GCP.

## usage 


```hcl
module "infra" {
  project_id = var.project_id
  region     = var.region

  #GKE
  image_repo         = "regentmarkets"
  gke_max_node_count = 4
  # https://cloud.google.com/compute/vm-instance-pricing
  gke_machine_type = "e2-medium"

  # PG
  postgres_enabled = true
  # https://cloud.google.com/sql/pricing
  postgres_tier         = "db-f1-micro"
  postgres_disk_size_gb = 10

  # Redis
  redis_enabled        = true
  redis_memory_size_gb = 1

  authorized_cidr_blocks = [
    { cidr_block = "1.1.1.1/32", display_name = "my-network" }
  ]
}
```
