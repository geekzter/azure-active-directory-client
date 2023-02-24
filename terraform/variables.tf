variable owner_object_id {
    default = ""
}

variable resource_prefix {
  description                  = "The prefix to put at the of resource names created"
  default                      = "test"
}

variable resource_suffix {
  description                  = "The suffix to put at the of resource names created"
  default                      = "" # Empty string triggers a random suffix
}