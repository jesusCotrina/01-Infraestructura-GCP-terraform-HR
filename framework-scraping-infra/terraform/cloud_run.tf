locals {
  cloud_runs = local.config_consolidado.cloud_run_config
}


resource "google_cloud_run_service" "gcr_scrapers" {
  for_each = { for key,value in local.cloud_runs : key=> value }
  name     = "${local.env_vars.prefijo_crun}-${each.key}-${each.value.name_scrap}"
  project  = local.env_vars.project
  location = local.env_vars.region
  template {
    spec {
      containers {
        image = "${local.env_vars.region}-docker.pkg.dev/${local.env_vars.project}/${local.env_vars.repositorio_artifact_registry}/${local.env_vars.prefijo_artifact}-${each.value.code}:latest"
        resources {
          limits = {
            memory = each.value.ram
            cpu    = tostring(
                        tonumber(replace(each.value.ram, "Gi", "")) > 8 ? 4 : 
                        tonumber(replace(each.value.ram, "Gi", "")) > 4 ? 2 : 1)
          }
        }
        dynamic "env" {
          for_each = each.value.cloud_run_config.parameters
          content {
            name  = env.key
            value = env.value
          }
        }

        env {
            name = "BUCKET_OUTPUT"
            value = local.env_vars.bucket_output
        }

        env {
            name = "PROJECT_ID"
            value = local.env_vars.project
        }

      }
      service_account_name        = local.env_vars.service_account_ejecucion
      container_concurrency       = 100
      timeout_seconds             = 3600
    }

    metadata {
      annotations = {
        "run.googleapis.com/client-name"  = "terraform"
        "deployment-timestamp" = timestamp()   
      }      
    }
  }
  
  traffic {
    percent         = 100
    latest_revision = true
  }
}