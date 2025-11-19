locals {
  cloud_runs = jsondecode(file("../config/cloud_run.json")).cloud_run_config
}


resource "google_cloud_run_service" "gcr_scrapers" {
  for_each = { for key,value in local.cloud_runs : key=> value }
  name     = "${local.env_vars.prefijo_crun}-${each.key}-${each.value.name_scrap}"
  project  = local.env_vars.project
  location = local.env_vars.region
  template {
    spec {
      containers {
        image = "${local.env_vars.region}-docker.pkg.dev/${local.env_vars.project}/${local.env_vars.repositorio_artifact_registry}/${local.env_vars.prefijo_artifact}-${each.value.code}-${each.value.name_scrap}:latest"
        resources {
          limits = {
            memory = each.value.ram
            cpu    = tostring(
                        tonumber(replace(each.value.ram, "Gi", "")) > 8 ? 4 : 
                        tonumber(replace(each.value.ram, "Gi", "")) > 4 ? 2 : 1)
          }
        }
        env {
            name = each.value.parameters.key
            value = jsonencode(each.value.parameters)
        }
      }
      service_account_name        = local.env_vars.service_account_ejecucion
      container_concurrency       = 100
      timeout_seconds             = 3600
    }

    metadata {
      annotations = {
        "run.googleapis.com/client-name"  = "terraform"
        "run.googleapis.com/vpc-access-egress"  = "private-ranges-only"
        "deployment-timestamp" = timestamp()   
      }      
    }
  }
  
  traffic {
    percent         = 100
    latest_revision = true
  }
}