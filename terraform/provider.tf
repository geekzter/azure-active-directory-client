provider azuread {
  alias                        = "home"
  tenant_id                    = var.home_tenant_id != null && var.home_tenant_id != "" ? var.home_tenant_id : null
}
data azuread_client_config home {
  provider                     = azuread.home
}
provider azuread {
  alias                        = "client"
  tenant_id                    = var.client_tenant_id != null && var.client_tenant_id != "" ? var.client_tenant_id : null
}
data azuread_client_config client {
  provider                     = azuread.client

}