# data azuread_client_config default {}

provider azuread {
  tenant_id                    = var.client_tenant_id != null && var.client_tenant_id != "" ? var.client_tenant_id : null
}

provider azuread {
  alias                        = "home"
  tenant_id                    = var.home_tenant_id != null && var.home_tenant_id != "" ? var.home_tenant_id : null
}