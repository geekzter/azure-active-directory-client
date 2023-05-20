variable client_tenant_id {
  type                         = string
  default                      = null
}

variable home_tenant_id {
  type                         = string
  default                      = null
}

variable resource_application_name {
  # https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application_published_app_ids
  description                  = "The name of the application to grant resource access to (no apaces)"
  default                      = "AzureDevOps"
}

variable resource_prefix {
  description                  = "The prefix to put at the of resource names created"
  default                      = "test"
}

variable resource_suffix {
  description                  = "The suffix to put at the of resource names created"
  default                      = null # Empty string triggers a random suffix
}