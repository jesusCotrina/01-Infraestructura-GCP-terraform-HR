
locals {
  config = jsondecode(file("../config/cloud_run.json"))
  env_vars = jsondecode(file("../env.json"))
}


resource "google_cloud_run_v2_service" "cloudrun_service" {
  name     = local.config.service_name
  project  = local.env_vars.project
  location = local.config.location

  template {
    containers {
      image = "${local.env_vars.region}-docker.pkg.dev/${local.env_vars.project}/${local.config.repositorio}/backend-motor-busqueda:latest"

      resources {
        cpu_idle         = true
        limits = {
          cpu    = local.config.cpu
          memory = local.config.memory
        }
      }

      # variables de entorno del JSON
      dynamic "env" {
        for_each = local.config.env
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }
  }

  traffic {
    type  = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service_iam_member" "invoker" {
  name     = google_cloud_run_v2_service.cloudrun_service.name
  location = local.config.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

