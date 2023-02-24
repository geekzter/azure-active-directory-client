data azuread_client_config current {}

resource azuread_application app {
  display_name                 = var.name
  owners                       = [var.owner_object_id]
  sign_in_audience             = "AzureADMyOrg"
  
  web {
    # implicit_grant {
    #   access_token_issuance_enabled = true
    # }
    redirect_uris              = ["http://localhost/"]
  }
}
