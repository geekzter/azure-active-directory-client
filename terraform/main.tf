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

module application {
  source                       = "./modules/application"
  name                         = "${var.resource_prefix}-aad-token-${terraform.workspace}-${local.suffix}"
  owner_object_id              = local.owner_object_id
}

module environment_variables {
  source                       = "./modules/environment-script"
  environment_variables        = {
    AZURE_CLIENT_ID            = module.application.application_id
    AZURE_TENANT_ID            = module.application.application_tenant_id
  }
}