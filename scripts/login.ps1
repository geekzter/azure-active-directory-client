#!/usr/bin/env pwsh
#Requires -Version 7
<# 
.SYNOPSIS 
    Performs a device code login to Azure AD and returns the access token
 
.EXAMPLE
    ./login.ps1
 
.EXAMPLE
    ./login.ps1 -ClientId 00000000-0000-0000-0000-000000000000 -TenantId 00000000-0000-0000-0000-000000000000
 
.EXAMPLE
    ./login.ps1 -Workspace test
#> 
param ( 
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [guid]
    $ClientId=($env:AZURE_CLIENT_ID ?? $env:ARM_CLIENT_ID),

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [guid]
    $TenantId=($env:AZURE_TENANT_ID ?? $env:ARM_TENANT_ID),

    [parameter(Mandatory=$false,ParameterSetName="AuthorizationCode",ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RedirectUrl,

    [parameter(Mandatory=$false)]
    [string]
    [ValidateSet("AuthorizationCode","DeviceCode")]
    $GrantType="DeviceCode",

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Workspace=($env:TF_WORKSPACE ?? 'default')
) 

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

# Create token request
$state = [guid]::NewGuid().Guid

if ($GrantType -eq "DeviceCode") {
    # There may be a race condition if the app was just created, try to get device code a few times
    Build-DeviceCodeRequest -State $state | Set-Variable deviceCodeRequest
    [int]$tries = 0
    [int]$maxTries = 5
    do {
        $tries++
        # Invoke-RestMethod @deviceCodeRequest | Set-Variable deviceCodeResponse
        Invoke-RestMethod @deviceCodeRequest `
                        -SkipHttpErrorCheck `
                        -StatusCodeVariable httpStatus `
                        | Set-Variable deviceCodeResponse
        Write-Debug "httpStatus: ${httpStatus}"
        $deviceCodeResponse | Format-List | Out-String | Write-Debug
        if ($deviceCodeResponse.error_description -match "AADSTS700016") {
            Write-Warning "The app doesn't exist (yet?), retrying in 5 seconds"
            Start-Sleep -Seconds 5
        }
    } while (($deviceCodeResponse.error_description -match "AADSTS700016") -and ($tries -lt $maxTries))

    # Prompt user to enter code
    [System.Diagnostics.Stopwatch]::StartNew() | Set-Variable timer
    $deviceCodeResponse | Format-List | Out-String | Write-Debug
    Set-Clipboard -Value $deviceCodeResponse.user_code
    Write-Host $deviceCodeResponse.message
    Open-Browser -Url $deviceCodeResponse.verification_url

    # Poll for token
    Build-DeviceCodeTokenRequest -Code $deviceCodeResponse.device_code -State $state | Set-Variable tokenRequest
    do {
        Start-Sleep -Seconds $deviceCodeResponse.interval
        Invoke-RestMethod @tokenRequest `
                        -SkipHttpErrorCheck `
                        -StatusCodeVariable httpStatus `
                        | Set-Variable tokenResponse
        Write-Debug "httpStatus: ${httpStatus}"
        $tokenResponse | Format-List | Out-String | Write-Debug
    } while (($tokenResponse.error -eq "authorization_pending") -and ($timer.Elapsed.TotalSeconds -le $deviceCodeResponse.expires_in))

    $accessToken = $tokenResponse.access_token
    if (!$accessToken) {
        Write-Error "Failed to get access token"
        $tokenResponse | Format-List
        exit 1
    }
    Write-Debug "accessToken: ${accessToken}"
    Write-Output $accessToken
} elseif ($GrantType -eq "AuthorizationCode") {
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
} else {
    throw "GrantType '${GrantType}' is not supported"
}

if (!(Validate-JWT $accessToken)) {
    exit 1
}