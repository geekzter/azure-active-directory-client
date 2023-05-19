output application_id {
  value       = data.azuread_application.app_registration.application_id
}
output application_name {
  value       = data.azuread_application.app_registration.display_name
}
output application_object_id {
  value       = data.azuread_application.app_registration.id
}
output application_portal_url {
  description = "This is the URL to the Azure Portal Enterprise (Service Principal) Application page for this application."
  value       = "https://portal.azure.com/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/Overview/objectId/${azuread_service_principal.enterprise_application.id}/appId/${data.azuread_application.app_registration.application_id}/preferredSingleSignOnMode~/null"
}
output application_registration_portal_url {
  description = "This is the URL to the Azure Portal Application Registration page for this application."
  value       = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/quickStartType~/null/sourceType/Microsoft_AAD_IAM/appId/${data.azuread_application.app_registration.application_id}/objectId/${data.azuread_application.app_registration.id}/isMSAApp~/false/defaultBlade/Overview/appSignInAudience/AzureADMyOrg/servicePrincipalCreated~/true"
}
output application_principal_id {
  value       = azuread_service_principal.enterprise_application.id
}
output application_tenant_id {
  value       = data.azuread_client_config.current.tenant_id
}
