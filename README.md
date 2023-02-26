# Azure Active Directory PowerShell Client

Demonstrates the use of AAD sign in from PowerShell script, leveraging [device authorization grant flow](https://learn.microsoft.com/azure/active-directory/develop/v2-oauth2-device-code). See [Headless samples](https://learn.microsoft.com/azure/active-directory/develop/sample-v2-code#headless) for C#, Java, Python flavors.

## Setup
This requires an AAD application to be created. This repo uses Terraform to do so. Specific settings that makes device code flow work are:

```hcl
  fallback_public_client_enabled = true 

  required_resource_access {
    # App id of the resource you want to access once logged in
    # e.g. 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d for DataBricks
    resource_app_id            = var.resource_app_id


    resource_access {
      # e.g. 739272be-e143-11e8-9f32-f2801f1b9fd1 for user_impersonation
      id                       = var.resource_access_id
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
```
