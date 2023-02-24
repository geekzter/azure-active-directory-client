function Get-TerraformDirectory {
    return (Join-Path (Split-Path $PSScriptRoot -Parent) "terraform")
}

function Login-Az (
    [parameter(Mandatory=$false)][switch]$DisplayMessages=$false
) {
    # Are we logged in? If so, is it the right tenant?
    $azureAccount = $null
    az account show 2>$null | ConvertFrom-Json | Set-Variable azureAccount
    if ($azureAccount -and "${env:ARM_TENANT_ID}" -and ($azureAccount.tenantId -ine $env:ARM_TENANT_ID)) {
        Write-Warning "Logged into tenant $($azureAccount.tenant_id) instead of $env:ARM_TENANT_ID (`$env:ARM_TENANT_ID)"
        $azureAccount = $null
    }
    
    $azLoginSwitches = "--allow-no-subscriptions"
    if (-not $azureAccount) {
        if ($env:CODESPACES -ieq "true") {
            $azLoginSwitches += " --use-device-code"
        }
        if ($env:ARM_TENANT_ID) {
            Write-Debug "az login -t ${env:ARM_TENANT_ID} -o none $($azLoginSwitches)"
            az login -t $env:ARM_TENANT_ID -o none $($azLoginSwitches)
        } else {
            Write-Debug "az login -o none $($azLoginSwitches)"
            az login -o none $($azLoginSwitches)
        }
    }
}

function Invoke (
    [string]$cmd
) {
    Write-Host "`n$cmd" -ForegroundColor Green 
    Invoke-Expression $cmd
    Validate-ExitCode $cmd
}

function Open-Browser (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Url
) {
    Write-Verbose "Opening browser to $Url"
    if ($IsLinux) {
        if (Get-Command xdg-open -ErrorAction SilentlyContinue) {
            xdg-open $Url
        } else {
            Write-Warning "xdg-open not found, please open the following URL in your browser:`n${Url}"
        }
    }
    if ($IsMacOS) {
        open $Url
    }
    if ($IsWindows) {
        start $Url
    }
}

function Validate-ExitCode (
    [string]$cmd
) {
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        Write-Warning "'$cmd' exited with status $exitCode"
        exit $exitCode
    }
}

function Write-RestError() {
    if ($_.ErrorDetails.Message) {
        try {
            $_.ErrorDetails.Message | ConvertFrom-Json | Set-Variable restError
            $restError | Format-List | Out-String | Write-Debug
            $message = $restError.message
        } catch {
            $message = $_.ErrorDetails.Message
        }
    } else {
        $message = $_.Exception.Message
    }
    Write-Warning $message
}