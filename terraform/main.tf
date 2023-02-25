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
  owner_object_id              = var.owner_object_id != "" ? lower(var.owner_object_id) : data.azuread_client_config.current.object_id
  suffix                       = var.resource_suffix != "" ? lower(var.resource_suffix) : random_string.suffix.result
}

module resource_application {
  source                       = "./modules/application-data"
  application_name             = var.resource_application_name
}

module application {
  source                       = "./modules/application"
  name                         = "${var.resource_prefix}-aad-client-${terraform.workspace}-${local.suffix}"
  owner_object_id              = local.owner_object_id
  resource_access_id           = module.resource_application.oauth2_permission_scope_ids["user_impersonation"]
  resource_app_id              = module.resource_application.application_id
}

module environment_variables {
  source                       = "./modules/environment-script"
  environment_variables        = {
    AZURE_CLIENT_ID            = module.application.application_id
    AZURE_TENANT_ID            = module.application.application_tenant_id
  }
}

data azuread_application_published_app_ids microsoft {}

data azuread_service_principal azure_dev_ops {
  # application_id               = data.azuread_application_published_app_ids.microsoft.result.AzureDevOps
  application_id               = data.azuread_application_published_app_ids.microsoft.result["AzureDevOps"]
}