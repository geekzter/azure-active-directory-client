output application_id {
  value       = module.application.application_id
}
output application_name {
  value       = module.application.application_name
}
output application_object_id {
  value       = module.application.application_object_id
}
output application_principal_id {
  value       = module.application.application_principal_id
}
output application_portal_url {
  description = "This is the URL to the Azure Portal Enterprise Application (Service Principal) page for this application."
  value       = module.application.application_portal_url 
}
output application_registration_portal_url {
  description = "This is the URL to the Azure Portal Application Registration page for this application."
  value       = module.application.application_registration_portal_url 
}

output application_tenant_id {
  value       = module.application.application_tenant_id
}

output environment_variables_script_relative_path {
  value       = module.environment_variables.file_name
}
output environment_variables_script_absolute_path {
  value       = abspath(module.environment_variables.file_name)
}

output terraform_client_id {
  value       = data.azuread_client_config.current.client_id
}
output terraform_object_id {
  value       = data.azuread_client_config.current.object_id
}
output terraform_tenant_id {
  value       = data.azuread_client_config.current.tenant_id
}

output resource_application_id {
  value       = module.resource_application.application_id
}
output resource_application_app_role_ids {
  value       = module.resource_application.app_role_ids
}
output resource_application_oauth2_permission_scope_ids {
  value       = module.resource_application.oauth2_permission_scope_ids
}
