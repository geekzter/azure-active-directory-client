#!/usr/bin/env pwsh
param ( 
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Workspace=($env:TF_WORKSPACE ?? 'default')
) 

$env:TF_WORKSPACE = $Workspace

function Prompt-User (
    [parameter(Mandatory=$false)][string]
    $PromptMessage = "Continue with next step",
    [parameter(Mandatory=$false)][string]
    $ContinueMessage = "Continue with next step",
    [parameter(Mandatory=$false)][string]
    $AbortMessage = "Aborting demo"
) {
    $defaultChoice = 0
    # Prompt to continue
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Continue", $ContinueMessage)
        [System.Management.Automation.Host.ChoiceDescription]::new("&Exit", $AbortMessage)
    )
    $decision = $Host.UI.PromptForChoice("`n", $PromptMessage, $choices, $defaultChoice)
    Write-Debug "Decision: $decision"

    if ($decision -eq 0) {
        Write-Host "$($choices[$decision].HelpMessage)"
    } else {
        Write-Host "$($PSStyle.Formatting.Warning)$($choices[$decision].HelpMessage)$($PSStyle.Reset)"
        exit $decision             
    }
}

$ErrorActionPreference = 'Stop'
try {
    Push-Location -Path $PSScriptRoot

    # Step 1: Create application with Terraform
    Prompt-User -PromptMessage "Create application with Terraform?" `
                -ContinueMessage "Creating application with Terraform"
    Write-Host "Running $(Resolve-Path ./deploy.ps1).Path"
    ./deploy.ps1
    Write-Host "`nEnterprise Application (Service Principal) url:"
    terraform -chdir='../terraform' output application_portal_url
    Write-Host "`nApplication registration url:"
    terraform -chdir='../terraform' output application_registration_portal_url

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
    ./login.ps1

    # Step 3: Capture redirected url
    Write-Host "Copy the url the browser redirects to (http://localhost/?code=...&state=...)"
    Read-Host -Prompt "Paste url here" | Set-Variable redirectUrl
    Write-Host "`nPasted url:`n $redirectUrl"

    # Step 4: Get token
    ./login.ps1 -RedirectUrl $redirectUrl | Set-Variable accessToken
    if ($accessToken) {
        Write-Host "`nAccess token:`n $accessToken"            
    } else {
        Write-Error "Could not get access token from login.ps1"
        exit 1
    }
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
