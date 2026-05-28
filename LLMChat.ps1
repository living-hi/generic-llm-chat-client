param(
    [string]$ProviderName,
    [string]$Endpoint,
    [string]$Model,
    [string]$ApiKeyEnv,
    [string]$ApiKey,
    [string]$AuthHeaderName,
    [string]$AuthScheme,
    [int]$TimeoutSeconds,
    [string]$ConfigPath = (Join-Path $PSScriptRoot "llm-chat.config.json"),
    [switch]$NoConfig
)

# Generic OpenAI-compatible chat client.
#
# Examples:
#   .\LLMChat.ps1
#   .\LLMChat.ps1 -ProviderName "OpenAI" -Endpoint "https://api.openai.com/v1/chat/completions" -Model "gpt-4.1" -ApiKeyEnv "OPENAI_API_KEY"
#   .\LLMChat.ps1 -ProviderName "Local" -Endpoint "http://localhost:11434/v1/chat/completions" -Model "qwen2.5:7b" -AuthHeaderName "none"
#
# Optional local config file beside this script: llm-chat.config.json
# Do not put API keys in files that will be published to GitHub.

$ErrorActionPreference = "Stop"

try {
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # Older Windows PowerShell hosts may not allow changing console encoding.
}

$defaults = @{
    providerName = "Jiutian"
    endpoint = "https://jiutian.10086.cn/largemodel/moma/api/v3/chat/completions"
    model = "jiutian/jiutian-lan-35b"
    apiKeyEnv = "LLM_API_KEY,OPENAI_API_KEY,JIUTIAN_API_KEY,JT_API_KEY,MOMA_API_KEY"
    authHeaderName = "Authorization"
    authScheme = "Bearer"
    timeoutSeconds = 120
    extraHeaders = @{}
}

function ConvertTo-Hashtable($value) {
    $table = @{}
    if ($null -eq $value) {
        return $table
    }

    if ($value -is [hashtable]) {
        return $value
    }

    $value.PSObject.Properties | ForEach-Object {
        $table[$_.Name] = $_.Value
    }
    return $table
}

function Read-Config($path) {
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) {
        return @{}
    }

    $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @{}
    }

    return ConvertTo-Hashtable ($raw | ConvertFrom-Json)
}

function First-NonBlank([string[]]$values) {
    foreach ($value in $values) {
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
    }
    return $null
}

function Get-ConfigValue($name, $parameterValue, $config, $defaultValue) {
    if (-not [string]::IsNullOrWhiteSpace($parameterValue)) {
        return $parameterValue.Trim()
    }
    if ($config.ContainsKey($name) -and -not [string]::IsNullOrWhiteSpace([string]$config[$name])) {
        return ([string]$config[$name]).Trim()
    }
    return $defaultValue
}

function Get-IntConfigValue($name, $parameterValue, $config, $defaultValue) {
    if ($parameterValue -gt 0) {
        return $parameterValue
    }
    if ($config.ContainsKey($name) -and [int]$config[$name] -gt 0) {
        return [int]$config[$name]
    }
    return $defaultValue
}

function Get-EnvNames($value) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        return @()
    }

    return $value.Split(",") |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}

function Get-FirstEnvValue($names) {
    foreach ($name in $names) {
        $processValue = [Environment]::GetEnvironmentVariable($name, "Process")
        if (-not [string]::IsNullOrWhiteSpace($processValue)) {
            return @{ Name = $name; Value = $processValue }
        }

        $userValue = [Environment]::GetEnvironmentVariable($name, "User")
        if (-not [string]::IsNullOrWhiteSpace($userValue)) {
            return @{ Name = $name; Value = $userValue }
        }
    }
    return $null
}

function Read-ApiKey($configuredApiKey, $envNames) {
    if (-not [string]::IsNullOrWhiteSpace($configuredApiKey)) {
        return $configuredApiKey
    }

    $envMatch = Get-FirstEnvValue $envNames
    if ($null -ne $envMatch) {
        $useSaved = Read-Host "Found API key in $($envMatch.Name). Use it? (Y/n)"
        if ($useSaved -eq "" -or $useSaved.ToLowerInvariant() -eq "y") {
            return $envMatch.Value
        }
    }

    $secureKey = Read-Host "Enter API Key" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function Get-AssistantContent($response) {
    if ($null -eq $response) {
        return ""
    }
    if ($response.choices -and $response.choices.Count -gt 0) {
        $choice = $response.choices[0]
        if ($choice.message -and $choice.message.content) {
            return [string]$choice.message.content
        }
        if ($choice.text) {
            return [string]$choice.text
        }
    }
    return ($response | ConvertTo-Json -Depth 20)
}

function Read-Utf8ResponseBody($response) {
    $stream = $response.GetResponseStream()
    $memory = New-Object System.IO.MemoryStream
    try {
        $buffer = New-Object byte[] 8192
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $memory.Write($buffer, 0, $read)
        }
        return [System.Text.Encoding]::UTF8.GetString($memory.ToArray())
    } finally {
        if ($stream) {
            $stream.Close()
        }
        $memory.Dispose()
        $response.Close()
    }
}

function Add-AuthHeader($request, $headerName, $scheme, $apiKey) {
    if ([string]::IsNullOrWhiteSpace($headerName) -or $headerName.ToLowerInvariant() -eq "none") {
        return
    }

    $headerValue = $apiKey
    if (-not [string]::IsNullOrWhiteSpace($scheme)) {
        $headerValue = "$scheme $apiKey"
    }

    if ($headerName.ToLowerInvariant() -eq "authorization") {
        $request.Headers.Add("Authorization", $headerValue)
    } else {
        $request.Headers.Add($headerName, $headerValue)
    }
}

function Send-ChatMessage($apiKey, $settings, $messages) {
    $payload = @{
        model = $settings.model
        messages = $messages.ToArray()
    }

    $json = $payload | ConvertTo-Json -Depth 20
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($json)

    $request = [System.Net.HttpWebRequest]::Create($settings.endpoint)
    $request.Method = "POST"
    $request.ContentType = "application/json; charset=utf-8"
    $request.Accept = "application/json"
    $request.Timeout = $settings.timeoutSeconds * 1000
    $request.ReadWriteTimeout = $settings.timeoutSeconds * 1000
    $request.ContentLength = $bodyBytes.Length

    Add-AuthHeader -request $request -headerName $settings.authHeaderName -scheme $settings.authScheme -apiKey $apiKey

    foreach ($headerName in $settings.extraHeaders.Keys) {
        if (-not [string]::IsNullOrWhiteSpace([string]$settings.extraHeaders[$headerName])) {
            $request.Headers.Add($headerName, [string]$settings.extraHeaders[$headerName])
        }
    }

    $requestStream = $request.GetRequestStream()
    try {
        $requestStream.Write($bodyBytes, 0, $bodyBytes.Length)
    } finally {
        $requestStream.Close()
    }

    try {
        $response = $request.GetResponse()
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            $errorText = Read-Utf8ResponseBody $_.Exception.Response
            throw "HTTP request failed. API response: $errorText"
        }
        throw
    }

    $responseText = Read-Utf8ResponseBody $response
    return $responseText | ConvertFrom-Json
}

$config = @{}
if (-not $NoConfig) {
    $config = Read-Config $ConfigPath
}

$settings = @{
    providerName = Get-ConfigValue "providerName" $ProviderName $config $defaults.providerName
    endpoint = Get-ConfigValue "endpoint" $Endpoint $config $defaults.endpoint
    model = Get-ConfigValue "model" $Model $config $defaults.model
    apiKeyEnv = Get-ConfigValue "apiKeyEnv" $ApiKeyEnv $config $defaults.apiKeyEnv
    authHeaderName = Get-ConfigValue "authHeaderName" $AuthHeaderName $config $defaults.authHeaderName
    authScheme = Get-ConfigValue "authScheme" $AuthScheme $config $defaults.authScheme
    timeoutSeconds = Get-IntConfigValue "timeoutSeconds" $TimeoutSeconds $config $defaults.timeoutSeconds
    extraHeaders = $defaults.extraHeaders
}

if ($config.ContainsKey("authHeaderName")) {
    $settings.authHeaderName = [string]$config["authHeaderName"]
}
if ($config.ContainsKey("authScheme")) {
    $settings.authScheme = [string]$config["authScheme"]
}
if ($PSBoundParameters.ContainsKey("AuthHeaderName")) {
    $settings.authHeaderName = $AuthHeaderName
}
if ($PSBoundParameters.ContainsKey("AuthScheme")) {
    $settings.authScheme = $AuthScheme
}

if ($config.ContainsKey("extraHeaders")) {
    $settings.extraHeaders = ConvertTo-Hashtable $config.extraHeaders
}

$messages = New-Object System.Collections.Generic.List[object]

Clear-Host
Write-Host "Generic LLM Chat Client"
Write-Host "Provider: $($settings.providerName)"
Write-Host "Endpoint: $($settings.endpoint)"
Write-Host "Model: $($settings.model)"
Write-Host "Commands: :exit quit, :clear clear context, :model change model, :endpoint change endpoint, :keyenv change key env, :config show config, :help help"
Write-Host ""

$apiKey = ""
if (-not ([string]::IsNullOrWhiteSpace($settings.authHeaderName) -or $settings.authHeaderName.ToLowerInvariant() -eq "none")) {
    $apiKey = Read-ApiKey -configuredApiKey $ApiKey -envNames (Get-EnvNames $settings.apiKeyEnv)
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Host "API Key is empty. Exit."
        exit 1
    }
}

while ($true) {
    Write-Host ""
    $userInput = Read-Host "You"

    if ([string]::IsNullOrWhiteSpace($userInput)) {
        continue
    }

    switch -Regex ($userInput.Trim()) {
        "^:exit$|^:quit$" {
            Write-Host "Bye."
            exit 0
        }
        "^:clear$" {
            $messages.Clear()
            Write-Host "Context cleared."
            continue
        }
        "^:model$" {
            Write-Host "Current model: $($settings.model)"
            $newModel = Read-Host "Enter a new model name, or press Enter to keep current"
            if (-not [string]::IsNullOrWhiteSpace($newModel)) {
                $settings.model = $newModel.Trim()
                Write-Host "Model changed to: $($settings.model)"
            }
            continue
        }
        "^:endpoint$" {
            Write-Host "Current endpoint: $($settings.endpoint)"
            $newEndpoint = Read-Host "Enter a new chat completions endpoint, or press Enter to keep current"
            if (-not [string]::IsNullOrWhiteSpace($newEndpoint)) {
                $settings.endpoint = $newEndpoint.Trim()
                Write-Host "Endpoint changed to: $($settings.endpoint)"
            }
            continue
        }
        "^:keyenv$" {
            Write-Host "Current API key env list: $($settings.apiKeyEnv)"
            $newApiKeyEnv = Read-Host "Enter comma-separated env names, or press Enter to keep current"
            if (-not [string]::IsNullOrWhiteSpace($newApiKeyEnv)) {
                $settings.apiKeyEnv = $newApiKeyEnv.Trim()
                $apiKey = Read-ApiKey -configuredApiKey "" -envNames (Get-EnvNames $settings.apiKeyEnv)
                Write-Host "API key source changed."
            }
            continue
        }
        "^:config$" {
            $safeSettings = $settings.Clone()
            $safeSettings.configPath = $ConfigPath
            $safeSettings | ConvertTo-Json -Depth 10 | Write-Host
            continue
        }
        "^:help$" {
            Write-Host ":exit     quit"
            Write-Host ":clear    clear current conversation context"
            Write-Host ":model    view or change model"
            Write-Host ":endpoint view or change chat completions endpoint"
            Write-Host ":keyenv   view or change API key environment variable names"
            Write-Host ":config   show current non-secret configuration"
            continue
        }
    }

    $messages.Add(@{ role = "user"; content = $userInput })

    try {
        Write-Host "$($settings.providerName): " -NoNewline
        $response = Send-ChatMessage -apiKey $apiKey -settings $settings -messages $messages
        $answer = Get-AssistantContent $response
        Write-Host $answer
        $messages.Add(@{ role = "assistant"; content = $answer })
    } catch {
        $messages.RemoveAt($messages.Count - 1)
        Write-Host ""
        Write-Host "Request failed: $($_.Exception.Message)"
    }
}
