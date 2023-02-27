data azuread_client_config current {}

resource azuread_application app_registration {
  display_name                 = var.name
 
  # Required for device code flow to prevent 'error "invalid_client" occurred while requesting token: AADSTS7000218: The request body must contain the following parameter: 'client_assertion' or 'client_secret'.'
  fallback_public_client_enabled = true 

  feature_tags {
    enterprise                 = true
    hide                       = true
  }
 
  owners                       = [var.owner_object_id]
  sign_in_audience             = "AzureADMyOrg"
  
  public_client {
    redirect_uris              = [
      "http://localhost",
      "https://login.microsoftonline.com/common/oauth2/nativeclient"
    ]
  }

  required_resource_access {
    resource_app_id            = var.resource_app_id

    resource_access {
      id                       = var.resource_access_id
      type                     = "Scope"
    }
  }
  required_resource_access {
    resource_app_id            = "00000002-0000-0000-c000-000000000000" # AAD Graph

    resource_access {
      id                       = "311a71cc-e848-46a1-bdf8-97ff7156d8e6" # User.Read
      type                     = "Scope"
    }
  }

  required_resource_access {
    resource_app_id            = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id                       = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type                     = "Scope"
    }
  }
}

resource azuread_service_principal enterprise_application {
  application_id               = azuread_application.app_registration.application_id
  owners                       = [var.owner_object_id]

  feature_tags {
    enterprise                 = true
    hide                       = true
  }

  saml_single_sign_on {
    relay_state                = null
  }
}