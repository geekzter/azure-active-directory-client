# data azuread_client_config default {}

provider azuread {
  tenant_id                    = var.tenant_id != null && var.tenant_id != "" ? var.tenant_id : null
}