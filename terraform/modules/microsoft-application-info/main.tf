data azuread_application_published_app_ids microsoft {}

data azuread_service_principal application {
  application_id               = data.azuread_application_published_app_ids.microsoft.result[var.application_name]
}