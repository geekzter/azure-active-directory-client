$scope = "${env:DEMO_RESOURCE_APP_ID}/.default"

function Build-LoginUrl () {
    $State ??= [guid]::NewGuid().Guid
    $loginUrl = "https://login.microsoftonline.com/${TenantId}/oauth2/v2.0/authorize"
    $loginUrl += "?client_id=${ClientId}"
    $loginUrl += "&scope=$([uri]::EscapeDataString('${scope}'))"
    $loginUrl += "&state=${State}"
    $loginUrl += "&response_type=code"
    $loginUrl += "&redirect_uri=$([uri]::EscapeDataString('http://localhost'))"
    $loginUrl += "&response_mode=query"

    Write-Debug "Login URL: ${loginUrl}"
    return $loginUrl
}

function Build-DeviceCodeRequest (
    [parameter(Mandatory=$true)]
    [string]
    $State
) {
    $requestBody = @{
        client_id    = $ClientId
        redirect_uri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
        scope        = $scope
        state        = $State
    }
    $requestBody | Format-Table | Out-String | Write-Debug
    $request = @{
        Method       = 'Post'
        Uri          = "https://login.microsoftonline.com/${TenantID}/oauth2/devicecode"
        ContentType  = 'application/x-www-form-urlencoded'
        Body         = $requestBody
    }
    $request | Format-Table | Out-String | Write-Debug

    return $request
}

function Build-DeviceCodeTokenRequest (
    [parameter(Mandatory=$true)]
    [string]
    $Code,

    [parameter(Mandatory=$false)]
    [string]
    $State
) {
    $requestBody = @{
        grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
        code        = $Code
        client_id   = $ClientId
        state       = $State
    }
    $requestBody | Format-Table | Out-String | Write-Debug
    $request = @{
        Method      = 'POST'
        Uri         = "https://login.microsoftonline.com/${TenantId}/oauth2/token"
        ContentType = 'application/x-www-form-urlencoded'
        Body        = $requestBody
    }
    $request | Format-Table | Out-String | Write-Debug

    return $request
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
        Uri         = "https://login.microsoftonline.com/${TenantId}/oauth2/v2.0/token"
        ContentType = 'application/x-www-form-urlencoded'
        Body        = @{
            client_id     = $ClientId
            scope         = $scope
            code          = $Code
            redirect_uri  = 'http://localhost'
            grant_type    = 'authorization_code'
            state         = $State
        }
    }
    $request | Format-Table | Out-String | Write-Debug

    return $request
}

function Configure-TerraformWorkspace (
    [parameter(Mandatory=$true)]
    [string]
    $Workspace=($env:TF_WORKSPACE ?? "default")
) {
    $terraformWorkspaceVars = (Join-Path (Split-Path $PSScriptRoot -Parent) terraform "${Workspace}.tfvars")
    if (Test-Path $terraformWorkspaceVars) {
        $regexCallback = {
            $terraformEnvironmentVariableName = "ARM_$($args[0])".ToUpper()
            $script:environmentVariableNames += $terraformEnvironmentVariableName
            "`n`$env:${terraformEnvironmentVariableName}"
        }

        # Match relevant lines first
        $terraformVarsFileContent = (Get-Content $terraformWorkspaceVars | Select-String "(?m)^[^#\w]*(client_id|client_secret|subscription_id|tenant_id)")
        if ($terraformVarsFileContent) {
            $envScript = [regex]::replace($terraformVarsFileContent,"(client_id|client_secret|subscription_id|tenant_id)",$regexCallback,[System.Text.RegularExpressions.RegexOptions]::Multiline)
            if ($envScript) {
                Write-Verbose $envScript
                Invoke-Expression $envScript
            } else {
                Write-Warning "[regex]::replace removed all content from script"
            }
        } else {
            Write-Verbose "No matches"
        }
    }
}

function Get-TerraformDirectory {
    return (Join-Path (Split-Path $PSScriptRoot -Parent) "terraform")
}
function Get-TerraformOutput (
    [parameter(Mandatory=$true)][string]$outputName
) {
    terraform -chdir='../terraform' output -json $outputName 2>$null | ConvertFrom-Json | Write-Output
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

function Prompt-User (
    [parameter(Mandatory=$false)][string]
    $PromptMessage = "Continue with next step?",
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