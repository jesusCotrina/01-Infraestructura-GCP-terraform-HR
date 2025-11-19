locals {
  list_cloud_build = jsondecode(file(abspath("../cloud build/cloud build.json")))
  config_env       = jsondecode(file(abspath("../env.json")))
}

resource "google_cloudbuild_trigger" "cloud_build_triggers" {
  for_each = { for cb in local.list_cloud_build.triggers : cb.name => cb }

  name            = "${each.value.name}-${local.config_env.pre_env_name}"
  description     = each.value.description
  project         = each.value.project_id
  location        = each.value.region
  service_account = "projects/${each.value.project_id}/serviceAccounts/${each.value.service_account}"

  dynamic "git_file_source" {
    for_each = each.value.repo_uri != null ? [1] : []
    content {
      path      = lookup(each.value, "file_yaml", "cloudbuild.yaml")
      repo_type = lookup(each.value, "repo_type", "GITHUB")
      # revision puede ser refs/heads/<branch> o regex según tu uso en legacy
      revision  = "refs/heads/${lookup(each.value, "branch_name", "main")}"
      uri       = each.value.repo_uri
    }
  }

  dynamic "source_to_build" {
    for_each = each.value.repo_uri != null ? [1] : []
    content {
      uri       = each.value.repo_uri
      ref       = "refs/heads/${lookup(each.value, "branch_name", "main")}"
      repo_type = lookup(each.value, "repo_type", "GITHUB")
    }
  }

  dynamic "github" {
    for_each = lookup(each.value, "repo_type", "") == "GITHUB" ? [1] : []
    content {
      owner = lookup(each.value, "owner_repo", null)
      # si no tienes name, intenta extraerla del uri (último segmento)
      name  = lookup(each.value, "repo_name", basename(each.value.repo_uri))

      dynamic "push" {
        for_each = lookup(each.value, "event_type", "") == "push" ? [1] : []
        content {
          branch       = "^${lookup(each.value, "branch_name", "main")}$"

          invert_regex = false
        }
      }

      dynamic "pull_request" {
        for_each = lookup(each.value, "event_type", "") == "pull_request" ? [1] : []
        content {
          branch = "^${lookup(each.value, "branch_name", "main")}$"
        }
      }
    }
  }

  included_files = lookup(each.value, "include_files", ["**"])

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
