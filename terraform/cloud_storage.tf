locals {
  bucket_config = jsondecode(file("../cloud storage/buckets.json"))
}

resource "google_storage_bucket" "buckets" {
  for_each = { for bkt in local.bucket_config.buckets : bkt.name => bkt }

  name                        = each.value.name
  project                     = each.value.project
  location                    = each.value.location
  storage_class               = each.value.storage_class
  uniform_bucket_level_access = lookup(each.value, "uniform_bucket_level_access", true)
  force_destroy               = lookup(each.value, "force_destroy", false)
  public_access_prevention    = each.value.public_access_prevention 
  dynamic "versioning" {
    for_each = lookup(each.value, "versioning", false) ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "retention_policy" {
    for_each = lookup(each.value, "retention_policy", null) != null ? [each.value.retention_policy] : []
    content {
      retention_period = lookup(retention_policy.value, "retention_period", 0) * 86400
    }
  }

  # Optional labels
  labels = lookup(each.value, "labels", {})

  # Optional lifecycle rules (if you want)
  lifecycle_rule {
    # Esta regla elimina versiones NO actuales después de X días
    action {
      type = "Delete"
    }

    condition {
      age     = 7            # Días desde que la versión dejó de ser actual
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 2   # conservar solo 2 versiones previas
    }
  }

}
