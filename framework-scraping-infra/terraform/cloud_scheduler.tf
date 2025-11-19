locals {
  cloud_schedulers = jsondecode(file("../config/cloud_scheduler.json")).cloud_scheduler_config
  cloud_schedulers_config = {
    for code, sched in local.cloud_schedulers :
    code => merge(
      sched,
      {
        cloud_run_name = format(
          "%s-%s-%s",
          local.env_vars.prefijo_crun,
          code,
          local.cloud_runs[code].name_scrap
        )
      }
    )
  }

}

resource "google_cloud_scheduler_job" "gsc_jobcrun3" {
  for_each         = local.cloud_schedulers_config
  name             = "${local.env_vars.prefijo_scheduler}-${each.key}-${each.value.name}"
  description      = each.value.description
  schedule         = each.value.schedule
  attempt_deadline = "180s"
  project          = local.env_vars.project
  region           = local.env_vars.region
  time_zone        = each.value.time_zone
  http_target {
    http_method = "POST"
    #Activamos el control
    uri         = google_cloud_run_service.gcr_scrapers[each.key].status[0].url
    body        = base64encode(jsonencode({
      tipo                = "Activnado desde cloud run"
    }) )  

    headers     = {"Content-Type" = "application/json"}
    oidc_token {
      #Activamos el control
      audience              = google_cloud_run_service.gcr_scrapers[each.key].status[0].url
      service_account_email = local.env_vars.service_account_ejecucion
    }
  }
  retry_config {
    max_backoff_duration = "3600s"
    max_doublings        = 5
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
    retry_count          = 0
  }
  
}