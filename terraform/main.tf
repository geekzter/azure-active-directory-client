data azuread_client_config current {}

# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  numeric                      = false
  special                      = false
}

locals {
  environment_variables        = {
    AZURE_CLIENT_ID            = module.enterprise_application.application_id
    AZURE_TENANT_ID            = module.enterprise_application.application_tenant_id
    DEMO_RESOURCE_APP_ID       = module.resource_application.application_id
  }
  owner_object_id              = var.owner_object_id != null && var.owner_object_id != "" ? lower(var.owner_object_id) : data.azuread_client_config.current.object_id
  suffix                       = var.resource_suffix != null && var.resource_suffix != "" ? lower(var.resource_suffix) : random_string.suffix.result
}

module resource_application {
  source                       = "./modules/microsoft-application-info"
  application_name             = var.resource_application_name
}

module application_registration {
  source                       = "./modules/application-registration"
  name                         = "${var.resource_prefix}-${lower(var.resource_application_name)}-client-${terraform.workspace}-${local.suffix}"
  owner_object_id              = local.owner_object_id
  resource_access_id           = module.resource_application.oauth2_permission_scope_ids["user_impersonation"]
  resource_app_id              = module.resource_application.application_id
}

module enterprise_application {
  source                       = "./modules/enterprise-application"
  authn_app_id                 = module.application_registration.application_id
  owner_object_id              = local.owner_object_id
}

module environment_variables {
  source                       = "./modules/environment-script"
  environment_variables        = local.environment_variables
}