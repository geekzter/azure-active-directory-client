#!/usr/bin/env pwsh
#Requires -Version 7
[CmdletBinding(DefaultParameterSetName = 'GetToken')]
param ( 
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [guid]
    $ClientId=($env:AZURE_CLIENT_ID ?? $env:ARM_CLIENT_ID),

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [guid]
    $TenantId=($env:AZURE_TENANT_ID ?? $env:ARM_TENANT_ID),

    [parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RedirectUrl,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Workspace=($env:TF_WORKSPACE ?? 'default')
) 

function Build-LoginUrl () {
    $State ??= [guid]::NewGuid().Guid
    $loginUrl = "https://login.microsoftonline.com/${TenantId}/oauth2/v2.0/authorize"
    $loginUrl += "?client_id=${ClientId}"
    $loginUrl += "&scope=499b84ac-1321-427f-aa17-267ca6975798%2F.default"
    $loginUrl += "&state=${State}"
    $loginUrl += "&response_type=code"
    $loginUrl += "&redirect_uri=$([uri]::EscapeDataString('http://localhost'))"
    $loginUrl += "&response_mode=query"

    Write-Debug "Login URL: ${loginUrl}"
    return $loginUrl
}

function Build-TokenRequest (
    [parameter(Mandatory=$false)]
    [string]
    $RedirectUrl
) {
    if ($RedirectUrl) {
        $RedirectUrl -match "http(s)?://[^\/]+/\?code=(?<code>[^\&]+)\&state=(?<state>[^\&]+)" | Out-Null
        $Matches | Out-String | Write-Debug
        $Code = $Matches['code']
        $State = $Matches['state']
    }
    if (!$Code) {
        throw "Code is required"
    }
    if (!$State) {
        throw "State is required"
    }
    Write-Debug "Code: ${Code}"
    Write-Debug "State: ${State}"

    $request = @{
        Method      = 'Post'
        Uri         = [uri]"https://login.microsoftonline.com/${TenantId}/oauth2/v2.0/token"
        ContentType = 'application/x-www-form-urlencoded'
        Body        = @{
            client_id     = $ClientId
            scope         = '499b84ac-1321-427f-aa17-267ca6975798/.default'
            code          = $Code
            redirect_uri  = 'http://localhost'
            grant_type    = 'authorization_code'
            state         = $State
        }
    }
    $request | Format-Table | Out-String | Write-Debug

    return $request
}

. (Join-Path $PSScriptRoot functions.ps1)

# Propagate Terraform context
Join-Path (Split-Path $PSScriptRoot -Parent) data $Workspace set_environment_variables.ps1 | Set-Variable envVarsScript
if (Test-Path $envVarsScript) {
    . $envVarsScript
} else {
    Write-Warning "No environment variables script found for Terraform workspace '${Workspace}'. Pleas run deploy.ps1 to create resources."
    exit 1
}
. $envVarsScript

if (!$Code -and !$RedirectUrl) {
    $loginUrl = Build-LoginUrl
    # Write-Host $logonUrl
    Open-Browser -Url $loginUrl 
} else {
    $tokenRequest = Build-TokenRequest -RedirectUrl $RedirectUrl
    $tokenRequest | Format-Table | Out-String | Write-Debug
    Invoke-RestMethod @tokenRequest | Set-Variable tokenResponse

    $accessToken = $tokenResponse.access_token
    Write-Debug "accessToken: ${accessToken}"
    Write-Output $accessToken
}
