locals {
  list_cloud_build = jsondecode(file(abspath("../cloud build/cloud build.json")))
  config_env = jsondecode(file(abspath("../env.json")))
}

resource "google_cloudbuild_trigger" "cloud_build_triggers" {
  for_each = { for cb in local.list_cloud_build.triggers : cb.name => cb }

  name        = "${each.value.name}-${local.config_env.pre_env_name}"
  description = each.value.description
  project     = each.value.project
  location    = each.value.region
  service_account = "projects/${each.value.project}/serviceAccounts/${each.value.service_account}"

  dynamic "git_file_source" {
    for_each = each.value.repo_uri != null ? [1] : []
    content {
      path      = "${each.value.file_yaml}"
      repo_type = each.value.repo_type
      revision  = "^${lookup(each.value, "branch_name", local.lis_config_env.branch_name)}$"
      uri       = each.value.repo_uri
    }
  }

  dynamic "source_to_build" {
    for_each = each.value.repo_uri != null ? [1] : []
    content {
      uri       = each.value.repo_uri
      ref       = "refs/heads/${lookup(each.value, "branch_name", local.lis_config_env.branch_name)}"
      repo_type = each.value.repo_type
    }
  }

  dynamic "pubsub_config" {
    for_each = each.value.event_type == "pubsub" ? [1] : []
    content {
      topic = "projects/${local.lis_config_env.project}/topics/${each.value.pubsub_topic}"
    }
  }

  dynamic "trigger_template" {
    for_each = each.value.event_type == "push" ? [1] : []
    content {
      branch_name = "^${lookup(each.value, "branch_name", local.lis_config_env.branch_name)}$"
      repo_name   = basename(each.value.repo_uri)
    }
  }

  dynamic "github" {
  for_each = each.value.repo_type == "GITHUB" ? [1] : []

  content {
    owner = each.value.owner_repo
    name  = basename(each.value.repo_uri)

    # Push a ramas
    dynamic "push" {
      for_each = each.value.event_type == "push" ? [1] : []
      content {
        branch       = "^${lookup(each.value, "branch_name", local.lis_config_env.branch_name)}$"
        invert_regex = false
      }
    }

    # Pull request
    dynamic "pull_request" {
      for_each = each.value.event_type == "pull_request" ? [1] : []
      content {
        branch = "^${lookup(each.value, "branch_name", local.lis_config_env.branch_name)}$"
      }
    }
  }
  }

  # Webhook
  dynamic "webhook_config" {
    for_each = each.value.event_type == "webhook" ? [1] : []
    content {
      secret = "projects/${local.lis_config_env.project}/secrets/webhook-secret/versions/latest"
    }
  }

  substitutions = {   
      _ENV_NAME=   local.config_env.env_name 
      _PROJECT_ID=each.value.project
      _REGION_ID= each.value.project
    }

}