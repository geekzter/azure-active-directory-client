#!/usr/bin/env pwsh
#Requires -Version 7
[CmdletBinding(DefaultParameterSetName = 'GetToken')]
param ( 
    [parameter(Mandatory=$false,ParameterSetName="GetToken")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Code,

    [parameter(Mandatory=$false,ParameterSetName="GetToken")]
    [ValidateNotNullOrEmpty()]
    [string]
    $State,

    [parameter(Mandatory=$false,ParameterSetName="GetTokenWithRedirectUrl",ValueFromPipeline=$true)]
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
    $loginUrl = "https://login.microsoftonline.com/${env:AZURE_TENANT_ID}/oauth2/v2.0/authorize"
    $loginUrl += "?client_id=${env:AZURE_CLIENT_ID}"
    $loginUrl += "&scope=499b84ac-1321-427f-aa17-267ca6975798%2F.default"
    $loginUrl += "&state=${State}"
    $loginUrl += "&response_type=code"
    $loginUrl += "&redirect_uri=$([uri]::EscapeDataString('http://localhost'))"
    $loginUrl += "&response_mode=query"

    Write-Debug "Login URL: ${loginUrl}"
    return $loginUrl
}

function Build-TokenRequestBody (
    [parameter(Mandatory=$true,ParameterSetName="Inline")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Code,

    [parameter(Mandatory=$true,ParameterSetName="Inline")]
    [ValidateNotNullOrEmpty()]
    [string]
    $State,

    [parameter(Mandatory=$true,ParameterSetName="Url")]
    [ValidateNotNullOrEmpty()]
    [string]
    $RedirectUrl
) {
    if ($RedirectUrl) {
        $RedirectUrl -match "http(s)?://[^\/]+/\?code=(?<code>[^\&]+)\&state=(?<state>[^\&]+)"
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

    $requestBody = "&client_id=${env:AZURE_CLIENT_ID}"
    $requestBody += "&scope=499b84ac-1321-427f-aa17-267ca6975798%2F.default"
    $requestBody += "&code=${Code}"
    $requestBody += "&redirect_uri=http%3A%2F%2Flocalhost"
    $requestBody += "&grant_type=authorization_code"
    $requestBody += "&state=${State}"
    Write-Debug "requestBody: ${requestBody}"
    
    return $requestBody
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
    if ($RedirectUrl) {
        $requestBody = Build-TokenRequestBody -RedirectUrl $RedirectUrl
    } elseif ($Code) {
        $requestBody = Build-TokenRequestBody -Code $Code -State $State
    }
    $requestBody | Format-Table | Out-String | Write-Debug
    Invoke-RestMethod -Uri "https://login.microsoftonline.com/${env:ARM_TENANT_ID}/oauth2/v2.0/token" `
                      -Method Post `
                      -ContentType 'application/x-www-form-urlencoded' `
                      -Body $requestBody `
                      | Set-Variable tokenResponse

    $accessToken = $tokenResponse.access_token
    Write-Debug "accessToken: ${accessToken}"
    Write-Output $accessToken
}
