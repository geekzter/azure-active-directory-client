output application_id {
  value       = module.application.application_id
}
output application_name {
  value       = module.application.application_name
}
output application_object_id {
  value       = module.application.application_object_id
}
output application_portal_url {
  value       = module.application.application_portal_url 
}
output application_tenant_id {
  value       = module.application.application_tenant_id
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