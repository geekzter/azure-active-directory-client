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
  name                         = "${var.resource_prefix}-aad-token-${local.suffix}"
  owner_object_id              = local.owner_object_id
}