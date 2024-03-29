output application_id {
  value       = module.application_registration.application_id
}
output application_identifier_uri {
  value       = module.application_registration.application_identifier_uri
}
output application_name {
  value       = module.application_registration.application_name
}
output application_object_id {
  value       = var.provision_service_principal ? module.enterprise_application[0].application_object_id : null
}
output application_principal_id {
  value       = var.provision_service_principal ? module.enterprise_application[0].application_principal_id : null
}
output application_portal_url {
  description = "This is the URL to the Azure Portal Enterprise Application (Service Principal) page for this application."
  value       = var.provision_service_principal ? module.enterprise_application[0].application_portal_url : null
}
output application_registration_portal_url {
  description = "This is the URL to the Azure Portal Application Registration page for this application."
  value       = module.application_registration.application_registration_portal_url 
}

output application_registration_tenant_id {
  value       = module.application_registration.application_tenant_id
}

output client_tenant_id {
  value       = data.azuread_client_config.client.tenant_id
}

output enterprise_application_tenant_id {
  value       = var.provision_service_principal ? module.enterprise_application[0].application_tenant_id : null
}

output environment_variables {
  value       = local.environment_variables
}
output environment_variables_script_relative_path {
  value       = module.environment_variables.file_name
}
output environment_variables_script_absolute_path {
  value       = abspath(module.environment_variables.file_name)
}

output home_tenant_id {
  value       = data.azuread_client_config.home.tenant_id
}

# Uncomment to discover common application names and IDs
# output microsoft_applications {
#   value       = module.resource_application.microsoft_applications
# }

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
output resource_application_name {
  value       = var.resource_application_name
}
# output resource_application_app_role_ids {
#   value       = module.resource_application.app_role_ids
# }
# output resource_application_oauth2_permission_scope_ids {
#   value       = module.resource_application.oauth2_permission_scope_ids
# }