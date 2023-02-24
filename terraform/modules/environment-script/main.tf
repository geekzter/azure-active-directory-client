locals {
  file_name                    = "${path.root}/../data/${terraform.workspace}/set_environment_variables.ps1"
  set_environment_variables_script = templatefile("${path.module}/set_environment_variables.template.ps1",
  {
    environment                = var.environment_variables
  })
}

resource local_file set_environment_variables_script {
  content                      = local.set_environment_variables_script
  filename                     = local.file_name
}
