[CmdletBinding()]
param(
    [string]$ApiKey,
    [string]$Endpoint = "https://cdx.2brain.pro/backend-api/codex",
    [string]$ModelsUrl = "https://cdx.2brain.pro/v1/models",
    [string]$Model = "gpt-5.6-luna",
    [switch]$DryRun,
    [switch]$NoDesktop
)

$ErrorActionPreference = "Stop"
$ManagedStart = "# BEGIN CODEX-LB MANAGED"
$ManagedEnd = "# END CODEX-LB MANAGED"
$DesktopStoreId = "9PLM9XGG6VKS"

function Fail([string]$Message) { throw $Message }

function Find-CodexCli {
    $command = Get-Command codex -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }

    $candidates = @(
        (Join-Path $HOME ".local\bin\codex.exe"),
        (Join-Path $HOME ".codex\packages\standalone\current\bin\codex.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\OpenAI\Codex\bin\codex.exe")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}

function Find-CodexDesktop {
    $results = [System.Collections.Generic.List[object]]::new()
    $paths = @(
        (Join-Path $env:LOCALAPPDATA "Programs\ChatGPT\ChatGPT.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\Codex\Codex.exe"),
        (Join-Path $env:ProgramFiles "ChatGPT\ChatGPT.exe"),
        (Join-Path $env:ProgramFiles "Codex\Codex.exe")
    )
    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            $version = [Diagnostics.FileVersionInfo]::GetVersionInfo($path).FileVersion
            $results.Add([pscustomobject]@{ Kind = "Executable"; Name = "Codex Desktop"; Version = $version; Path = $path })
        }
    }

    if (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue) {
        Get-AppxPackage -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '(?i)(openai|chatgpt|codex)' } |
            ForEach-Object {
                $launchPath = "shell:AppsFolder\$($_.PackageFamilyName)!App"
                $results.Add([pscustomobject]@{ Kind = "Appx"; Name = $_.Name; Version = $_.Version.ToString(); Path = $_.InstallLocation; LaunchPath = $launchPath })
            }
    }

    $uninstallRoots = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($root in $uninstallRoots) {
        Get-ItemProperty $root -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match '(?i)^(chatgpt|codex)(\s|$)' } |
            ForEach-Object {
                $results.Add([pscustomobject]@{ Kind = "Registry"; Name = $_.DisplayName; Version = $_.DisplayVersion; Path = $_.InstallLocation })
            }
    }
    return @($results | Sort-Object Kind, Path -Unique)
}

function Find-UsableCodexDesktop {
    return @(Find-CodexDesktop | Where-Object { $_.Kind -eq "Executable" -or $_.Kind -eq "Appx" })
}

function Wait-ForCodexDesktop([int]$Attempts = 30) {
    for ($attempt = 0; $attempt -lt $Attempts; $attempt++) {
        $desktop = @(Find-UsableCodexDesktop)
        if ($desktop.Count -gt 0) { return $desktop }
        Start-Sleep -Seconds 2
    }
    return @()
}

function Backup-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $backup = "$Path.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
    if (Test-Path -LiteralPath $backup) { $backup = "$backup-$PID" }
    Copy-Item -LiteralPath $Path -Destination $backup
    Write-Host "Backup: $backup"
}

function Read-HiddenApiKey {
    $secure = Read-Host "Enter Codex-LB API key" -AsSecureString
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}

function Add-WindowsPowerShellArchitectureCompatibility([string]$Source) {
    $runtimeProbe = '$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture'
    if (-not $Source.Contains($runtimeProbe)) { return $Source }

    # Windows PowerShell 5.1 can load RuntimeInformation without exposing
    # OSArchitecture. The official Codex bootstrap runs in strict mode, so that
    # missing static property aborts an otherwise supported ARM64/x64 install.
    $environmentProbe = '$architecture = if (($env:PROCESSOR_ARCHITEW6432, $env:PROCESSOR_ARCHITECTURE) -contains "ARM64") { "Arm64" } elseif (($env:PROCESSOR_ARCHITEW6432, $env:PROCESSOR_ARCHITECTURE) -contains "AMD64") { "X64" } else { $env:PROCESSOR_ARCHITECTURE }'
    return $Source.Replace($runtimeProbe, $environmentProbe)
}

function Install-CodexCli {
    Write-Host "Installing the official Codex CLI..."
    $previous = $env:CODEX_NON_INTERACTIVE
    $env:CODEX_NON_INTERACTIVE = "1"
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "https://chatgpt.com/codex/install.ps1"
        if ($response.Content -is [byte[]]) {
            $source = [Text.Encoding]::UTF8.GetString($response.Content)
        } else {
            $source = [string]$response.Content
        }
        $source = Add-WindowsPowerShellArchitectureCompatibility $source
        $script = [scriptblock]::Create($source)
        & $script
    } finally {
        $env:CODEX_NON_INTERACTIVE = $previous
    }
}

function Install-OrUpdate-CodexDesktop([bool]$AlreadyInstalled) {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $winget) { return $false }

    if ($AlreadyInstalled) {
        Write-Host "Checking Codex Desktop updates..."
        $action = "upgrade"
    } else {
        Write-Host "Installing Codex Desktop from Microsoft Store..."
        $action = "install"
    }
    $arguments = @(
        $action, "--id", $DesktopStoreId, "--exact", "--source", "msstore",
        "--silent", "--disable-interactivity", "--accept-package-agreements",
        "--accept-source-agreements"
    )
    $process = Start-Process -FilePath $winget.Source -ArgumentList $arguments -NoNewWindow -PassThru
    if (-not $process.WaitForExit(600000)) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        Write-Warning "Microsoft Store did not finish within 10 minutes"
        return $false
    }
    if ($process.ExitCode -eq 0) {
        if (@(Wait-ForCodexDesktop).Count -gt 0) { return $true }
        Write-Warning "Microsoft Store reported success, but Codex Desktop was not found"
        return $false
    }
    if ($AlreadyInstalled) {
        Write-Host "No newer Codex Desktop package is available."
        return $true
    }

    Write-Warning "Microsoft Store installation was unavailable; will try the official Codex app installer"
    return $false
}

if ($Endpoint -notmatch '^https://[A-Za-z0-9._:/-]+$') { Fail "Invalid HTTPS endpoint" }
if ($ModelsUrl -notmatch '^https://[A-Za-z0-9._:/-]+$') { Fail "Invalid HTTPS models URL" }
if ($Model -notmatch '^[A-Za-z0-9._-]+$') { Fail "Invalid model name" }

$desktop = @(Find-CodexDesktop)
$codex = Find-CodexCli
Write-Host "System: Windows $([Environment]::OSVersion.Version) $env:PROCESSOR_ARCHITECTURE"
if ($desktop.Count -eq 0) {
    Write-Host "Codex Desktop: not found"
} else {
    foreach ($app in $desktop) { Write-Host "Codex Desktop: $($app.Name) $($app.Version) [$($app.Kind)] $($app.Path)" }
}
if ($codex) { Write-Host "Codex CLI: $codex ($(& $codex --version))" }
else { Write-Host "Codex CLI: not found" }

if ($DryRun) {
    Write-Host "Dry run complete; no changes were made."
    return
}

if ($codex) {
    Write-Host "Updating Codex CLI..."
    & $codex update
    if ($LASTEXITCODE -ne 0) { Install-CodexCli }
} elseif ($desktop.Count -eq 0) {
    Install-CodexCli
}
$codex = Find-CodexCli
if ($desktop.Count -eq 0 -and -not $codex -and $NoDesktop) {
    Fail "Codex CLI installation was not confirmed"
}

$codexHome = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) { Join-Path $HOME ".codex" } else { $env:CODEX_HOME }
New-Item -ItemType Directory -Force -Path $codexHome | Out-Null
$keyPath = Join-Path $codexHome "codex-lb-api-key"

if ([string]::IsNullOrWhiteSpace($ApiKey)) { $ApiKey = $env:CODEX_LB_API_KEY }
if ([string]::IsNullOrWhiteSpace($ApiKey)) { $ApiKey = [Environment]::GetEnvironmentVariable("CODEX_LB_API_KEY", "User") }
if ([string]::IsNullOrWhiteSpace($ApiKey) -and (Test-Path -LiteralPath $keyPath)) {
    $saved = [IO.File]::ReadAllText($keyPath).Trim()
    if (-not [string]::IsNullOrWhiteSpace($saved)) {
        $answer = Read-Host "Saved Codex-LB key found. Reuse it? [Y/n]"
        if ($answer -notmatch '^(?i:n|no)$') { $ApiKey = $saved }
    }
}
if ([string]::IsNullOrWhiteSpace($ApiKey)) { $ApiKey = Read-HiddenApiKey }
if ([string]::IsNullOrWhiteSpace($ApiKey)) { Fail "API key cannot be empty" }
if ($ApiKey.Contains("`r") -or $ApiKey.Contains("`n")) { Fail "API key contains a newline" }
$env:CODEX_LB_API_KEY = $ApiKey

try {
    $models = Invoke-RestMethod -Uri $ModelsUrl -Headers @{ Authorization = "Bearer $ApiKey" } -TimeoutSec 30
} catch {
    if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -in 401, 403) { Fail "Codex-LB rejected the API key" }
    Fail "Codex-LB model check failed: $($_.Exception.Message)"
}
$modelIds = @($models.data | ForEach-Object { [string]$_.id } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
if ($modelIds.Count -eq 0) { Fail "Codex-LB model catalog is empty" }
Write-Host ("Codex-LB key and model catalog: {0} model(s) available." -f $modelIds.Count)

$utf8 = [Text.UTF8Encoding]::new($false)
$keyTemp = "$keyPath.$PID.tmp"
[IO.File]::WriteAllText($keyTemp, $ApiKey + [Environment]::NewLine, $utf8)
Move-Item -Force -LiteralPath $keyTemp -Destination $keyPath
[Environment]::SetEnvironmentVariable("CODEX_LB_API_KEY", $ApiKey, "User")
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    & icacls.exe $keyPath /inheritance:r /grant:r ($identity + ":(F)") | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Warning "Could not tighten ACL on $keyPath" }
} catch { Write-Warning "Could not tighten ACL on $keyPath" }

$configPath = Join-Path $codexHome "config.toml"
$existing = if (Test-Path -LiteralPath $configPath) { [IO.File]::ReadAllText($configPath) } else { "" }
$managedPattern = "(?ms)^" + [regex]::Escape($ManagedStart) + "\r?\n.*?^" + [regex]::Escape($ManagedEnd) + "\r?\n?"
$clean = [regex]::Replace($existing, $managedPattern, "")
$providerPattern = '(?ms)^\s*\[model_providers\.codex-lb\]\s*\r?\n.*?(?=^\s*\[|\z)'
$clean = [regex]::Replace($clean, $providerPattern, "")
$topKeys = '(?m)^(model|review_model|model_provider|model_catalog_json)\s*=.*(?:\r?\n|$)'
$clean = [regex]::Replace($clean, $topKeys, "").Trim()
$providerLines = @(
    ('model = "{0}"' -f $Model),
    ('review_model = "{0}"' -f $Model),
    'model_provider = "codex-lb"',
    '',
    $clean,
    '',
    $ManagedStart,
    '[model_providers.codex-lb]',
    'name = "openai"',
    ('base_url = "{0}"' -f $Endpoint.TrimEnd('/')),
    'wire_api = "responses"',
    'supports_websockets = true',
    'requires_openai_auth = false',
    'env_key = "CODEX_LB_API_KEY"',
    $ManagedEnd
)
$newConfig = (($providerLines | Where-Object { $null -ne $_ }) -join [Environment]::NewLine).Trim() + [Environment]::NewLine
Backup-File $configPath
$configTemp = "$configPath.$PID.tmp"
[IO.File]::WriteAllText($configTemp, $newConfig, $utf8)
Move-Item -Force -LiteralPath $configTemp -Destination $configPath

if ($codex) {
    Write-Host "Codex CLI after setup: $(& $codex --version)"
    & $codex doctor *> $null
    if ($LASTEXITCODE -ne 0) { Write-Warning "codex doctor reported diagnostics; run it manually for details" }
}

if (-not $NoDesktop) {
    $usableDesktop = @(Find-UsableCodexDesktop)
    [void](Install-OrUpdate-CodexDesktop ($usableDesktop.Count -gt 0))
    $usableDesktop = @(Find-UsableCodexDesktop)
    if ($usableDesktop.Count -eq 0 -and $codex) {
        Write-Host "Opening the official Codex Desktop installer..."
        & $codex app
        if ($LASTEXITCODE -ne 0) { Fail "The official Codex Desktop installer could not be started" }
        $usableDesktop = @(Wait-ForCodexDesktop)
    }
    if ($usableDesktop.Count -eq 0) {
        Fail "Codex Desktop installation was not confirmed; finish the installer and rerun this command"
    }
    $executable = $usableDesktop | Where-Object { $_.Kind -eq "Executable" } | Select-Object -First 1
    $appx = $usableDesktop | Where-Object { $_.Kind -eq "Appx" } | Select-Object -First 1
    if ($executable) {
        Start-Process -FilePath $executable.Path
    } elseif ($appx) {
        Start-Process -FilePath "explorer.exe" -ArgumentList $appx.LaunchPath
    } else {
        Fail "Codex Desktop was found but could not be launched"
    }
}

if ($NoDesktop) {
    Write-Host "Setup complete. Codex-LB configured; Desktop installation and launch were skipped."
} else {
    Write-Host "Setup complete. Fully restart Codex Desktop so it inherits the new provider environment."
}
