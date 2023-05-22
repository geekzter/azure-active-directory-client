data azuread_client_config current {}

data azuread_application app_registration {
  application_id               = var.authn_app_id
}

resource azuread_service_principal enterprise_application {
  application_id               = data.azuread_application.app_registration.application_id
  owners                       = [data.azuread_client_config.current.object_id]

  feature_tags {
    enterprise                 = true
    hide                       = true
  }

  saml_single_sign_on {
    relay_state                = null
  }
}