output application_id {
  value       = azuread_application.app.application_id
}
output application_name {
  value       = azuread_application.app.display_name
}
output application_object_id {
  value       = azuread_application.app.id
}
output application_portal_url {
  value       = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/quickStartType~/null/sourceType/Microsoft_AAD_IAM/appId/${azuread_application.app.application_id}"
}
output application_tenant_id {
  value       = data.azuread_client_config.current.tenant_id
}
