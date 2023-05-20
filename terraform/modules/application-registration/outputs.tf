output application_id {
  value       = azuread_application.app_registration.application_id
}
output application_name {
  value       = azuread_application.app_registration.display_name
}
output application_object_id {
  value       = azuread_application.app_registration.id
}
output application_registration_portal_url {
  description = "This is the URL to the Azure Portal Application Registration page for this application."
  value       = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/quickStartType~/null/sourceType/Microsoft_AAD_IAM/appId/${azuread_application.app_registration.application_id}/objectId/${azuread_application.app_registration.id}/isMSAApp~/false/defaultBlade/Overview/appSignInAudience/AzureADMyOrg/servicePrincipalCreated~/true"
}
output application_tenant_id {
  value       = data.azuread_client_config.home.tenant_id
}
