
locals {
  config = jsondecode(file("../config/cloud_run.json"))
  env_vars = jsondecode(file("../env.json"))
}


resource "google_cloud_run_service" "cloudrun_service" {
  name     = local.config.service_name
  project  = local.env_vars.project
  location = local.config.location

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "all"
    }
  }

  template {
    metadata {
      annotations = {
        "run.googleapis.com/client-name"  = "terraform"
        "deployment-timestamp"            = timestamp()
      }
    }

    spec {
      containers {
        image = "${local.env_vars.region}-docker.pkg.dev/${local.env_vars.project}/${local.config.repositorio}/backend-motor-busqueda:latest"
        
        dynamic "env" {
          for_each = local.config.env
          content {
            name  = env.key
            value = env.value
          }
        }
      }
      service_account_name        = local.env_vars.service_account_ejecucion
      container_concurrency       = 100
      timeout_seconds             = 3600
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  project  = local.env_vars.project
  location = local.config.location
  service  = google_cloud_run_service.cloudrun_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
