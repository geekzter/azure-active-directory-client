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
  description = "This is the URL to the Azure Portal Enterprise Application page for this application."
  value       = "https://ms.portal.azure.com/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/Overview/objectId/${azuread_service_principal.spn.id}/appId/${azuread_application.app.application_id}/preferredSingleSignOnMode~/null"
}
output application_registration_portal_url {
  description = "This is the URL to the Azure Portal Application Registration (Service Principal) page for this application."
  value       = "https://ms.portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/quickStartType~/null/sourceType/Microsoft_AAD_IAM/appId/${azuread_application.app.application_id}/objectId/${azuread_application.app.id}/isMSAApp~/false/defaultBlade/Overview/appSignInAudience/AzureADMyOrg/servicePrincipalCreated~/true"
}
output application_principal_id {
  value       = azuread_service_principal.spn.id
}
output application_tenant_id {
  value       = data.azuread_client_config.current.tenant_id
}
