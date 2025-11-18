locals {
  list_cloud_build = jsondecode(file(abspath("../cloud build/cloud build.json")))
  config_env       = jsondecode(file(abspath("../env.json")))
}

resource "google_cloudbuildv2_trigger" "cloud_build_triggers" {
  for_each = { for cb in local.list_cloud_build.triggers : cb.name => cb }

  name            = "${each.value.name}-${local.config_env.pre_env_name}"
  description     = each.value.description
  project         = each.value.project_id
  location        = each.value.region
  service_account = "projects/${each.value.project_id}/serviceAccounts/${each.value.service_account}"
  repository      = "projects/.../connections/.../repositories/<repo>"
  filename        = each.value.file_yaml

  build {
    dynamic "push" {
      for_each = each.value.event_type == "push" ? [1] : []
      content {
        branch = each.value.branch_name
        # O: tag = each.value.tag_name
      }
    }

    dynamic "pull_request" {
      for_each = each.value.event_type == "pull_request" ? [1] : []
      content {
        branch = each.value.branch_name
      }
    }

    # Para manual
    dynamic "manual" {
      for_each = each.value.event_type == "manual" ? [1] : []
      content {}
    }
  }

  dynamic "pubsub_config" {
    for_each = each.value.event_type == "pubsub" ? [1] : []
    content {
      topic = "projects/${each.value.project_id}/topics/${each.value.pubsub_topic}"
    }
  }

  # Webhook
  dynamic "webhook_config" {
    for_each = each.value.event_type == "webhook" ? [1] : []
    content {
      secret = "projects/${local.config_env.project_id}/secrets/webhook-secret/versions/latest"
    }
  }

  substitutions = {
    _ENV_NAME   = local.config_env.env_name
    _PROJECT_ID = each.value.project_id
    _REGION_ID  = each.value.project_id
  }

}
