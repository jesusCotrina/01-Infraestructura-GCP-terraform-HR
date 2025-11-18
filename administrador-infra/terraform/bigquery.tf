locals {
  dataset_config = jsondecode(file("../bigquery/datasets.json"))
}

resource "google_bigquery_dataset" "dataset" {
  for_each = {
    for d in local.dataset_config.datasets : d.dataset_name => d
  }

  dataset_id    = each.value.dataset_name
  location      = each.value.location
  friendly_name = each.value.friendly_name
  description   = each.value.description
  project       = each.value.project_id
}
