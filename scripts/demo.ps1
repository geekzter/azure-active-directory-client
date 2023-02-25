#!/usr/bin/env pwsh
#Requires -Version 7
<# 
.SYNOPSIS 
    Performs e2e demo
 
.DESCRIPTION
    Performs end-to-end demo of application creation, sign in, and use of access token to install Azure Pipeline agent locally.   

.EXAMPLE
    ./demo.ps1
 
.EXAMPLE
    ./demo.ps1 -Workspace test
#> 
param ( 
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Workspace=($env:TF_WORKSPACE ?? 'default')
) 
$env:TF_WORKSPACE = $Workspace
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot functions.ps1)

try {
    Push-Location -Path $PSScriptRoot

    # Step 1: Create application with Terraform
    Configure-TerraformWorkspace -Workspace $Workspace
    Prompt-User -PromptMessage "Create application with Terraform?" `
                -ContinueMessage "Creating application with Terraform"
    $appWillBeCreated = [string]::IsNullOrEmpty((Get-TerraformOutput 'application_principal_id'))
    Write-Host "Running $(Resolve-Path ./deploy.ps1)"
    ./deploy.ps1 -apply
    Write-Host "`nEnterprise Application (Service Principal) url:"
    Get-TerraformOutput 'application_portal_url'
    if ($appWillBeCreated) {
        Open-Browser -Url (Get-TerraformOutput 'application_portal_url')
    }
    Write-Host "`nApplication registration url:"
    Get-TerraformOutput 'application_registration_portal_url'
    if ($appWillBeCreated) {
        Open-Browser -Url (Get-TerraformOutput 'application_registration_portal_url')
    }

    # Step 1a: Propagate Terraform output to environment variables
    Join-Path (Split-Path $PSScriptRoot -Parent) data $Workspace set_environment_variables.ps1 | Set-Variable envVarsScript
    if (Test-Path $envVarsScript) {
        . $envVarsScript
    } else {
        Write-Warning "No environment variables script found for Terraform workspace '${Workspace}'. Pleas run deploy.ps1 to create resources."
        exit 1
    }
    . $envVarsScript
    Write-Host "`nPropagating Terraform output as environment variables:"
    Get-ChildItem -Path Env: -Recurse -Include AZURE_*NT_ID | Sort-Object -Property Name |  Format-Table -HideTableHeaders

    # Step 2: Login with AAD
    Prompt-User -PromptMessage "Log into AAD (opens browser window)?" `
                -ContinueMessage "Opening browser window to log into AAD..."
    Write-Host "Running $(Resolve-Path ./login.ps1)"
    ./login.ps1 | Set-Variable accessToken
} finally {
    Pop-Location
}

# Step 5: Use token to install agent locally
if (Test-Path ../../azure-pipeline-scripts/scripts/install_agent.ps1) {
    try {
        Push-Location -Path ../../azure-pipeline-scripts/scripts

        Prompt-User -PromptMessage "Install Azure Pipeline agent locally?" `
                    -ContinueMessage "Installing Azure Pipeline agent locally..."

        Write-Host "Running $(Resolve-Path ./install_agent.ps1)"
        ./install_agent.ps1 -Token $accessToken
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "Could not find ../../azure-pipeline-scripts/scripts/install_agent.ps1 script. Please clone https://github.com/geekzter/azure-pipeline-scripts into ../../azure-pipeline-scripts"
    exit 1
}
