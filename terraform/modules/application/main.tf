data azuread_client_config current {}

resource random_uuid "widgets_scope_id" {}

resource azuread_application app {
  display_name                 = var.name
  owners                       = [var.owner_object_id]
  sign_in_audience             = "AzureADMyOrg"
  

  required_resource_access {
    resource_app_id            = "499b84ac-1321-427f-aa17-267ca6975798" # Azure DevOps

    resource_access {
      id                       = "ee69721e-6c3a-468f-a9ec-302d16a4c599" # user_impersonation
      type                     = "Scope"
    }
  }
  required_resource_access {
    resource_app_id            = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d" # AzureDataBricks

    resource_access {
      id                       = "739272be-e143-11e8-9f32-f2801f1b9fd1" # user_impersonation
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

  web {
    # implicit_grant {
    #   access_token_issuance_enabled = true
    # }
    redirect_uris              = ["http://localhost/"]
  }
}
