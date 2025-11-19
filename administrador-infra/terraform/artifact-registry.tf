locals {
  repos = jsondecode(file("../artifact-registry/repositorios.json")).repositories
}

resource "google_artifact_registry_repository" "repos" {
  for_each = {for r in local.repos : r.id => r}
  project       = each.value.project_id
  location      = each.value.location
  repository_id = each.value.id

  description = lookup(each.value, "description", null)
  format      = each.value.format

  dynamic "docker_config" {
    for_each = each.value.format == "DOCKER" ? [1] : []
    content {
      immutable_tags = false
    }
  }
}