output application_id {
  value       = data.azuread_application_published_app_ids.microsoft.result[var.application_name]
}

output microsoft_applications {
  value       = data.azuread_application_published_app_ids.microsoft.result
}

output oauth2_permission_scope_ids {
  value       = data.azuread_service_principal.application.oauth2_permission_scope_ids
}