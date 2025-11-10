locals {
  list_service_accountsname = jsondecode(file(abspath("../service-account/service-accounts.json")))
  list_sa_roles = {
    for sa_role in flatten([
      for sa in local.list_service_accountsname : [
        for role in sa.roles : {
          key        = "${sa.name}-${role}"
          project_id = sa.project_id
          account_id = sa.name
          role       = role
        }
      ]
    ]) : sa_role.key => sa_role
  }

}

resource "google_service_account" "service_accounts" {
  for_each     = { for sa in local.list_service_accountsname : sa.name => sa }
  account_id   = each.value.name
  display_name = each.value.display_name
}

resource "google_project_iam_member" "bindings" {
  for_each = local.list_sa_roles
  project  = each.value.project_id
  role     = each.value.role
  member   = "serviceAccount:${each.value.account_id}@${each.value.project_id}.iam.gserviceaccount.com"
}

