$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $repoRoot "Install-CodexLb.ps1"
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("codex-lb-test-" + [Guid]::NewGuid().ToString("N"))
$binPath = Join-Path $testRoot "bin"
$codexHome = Join-Path $testRoot ".codex"

$oldCodexHome = $env:CODEX_HOME
$oldPath = $env:PATH
$oldProcessKey = $env:CODEX_LB_API_KEY
$oldUserKey = [Environment]::GetEnvironmentVariable("CODEX_LB_API_KEY", "User")

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function global:Invoke-RestMethod {
    [CmdletBinding()]
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [int]$TimeoutSec
    )
    return [pscustomobject]@{
        data = @(
            [pscustomobject]@{ id = "gpt-5.6-luna" },
            [pscustomobject]@{ id = "gpt-5.6-terra" }
        )
    }
}

try {
    New-Item -ItemType Directory -Force -Path $binPath, $codexHome | Out-Null
    $fakeCodex = Join-Path $binPath "codex.cmd"
    [IO.File]::WriteAllText(
        $fakeCodex,
        "@echo off`r`nif `"%~1`"==`"--version`" echo codex-cli test`r`nexit /b 0`r`n",
        [Text.Encoding]::ASCII
    )

    $env:CODEX_HOME = $codexHome
    $env:CODEX_LB_API_KEY = "test-secret"
    $env:PATH = $binPath + [IO.Path]::PathSeparator + $oldPath

    & $installer -ApiKey "test-secret" -ModelsUrl "https://example.invalid/v1/models" -NoDesktop
    & $installer -ApiKey "test-secret" -ModelsUrl "https://example.invalid/v1/models" -NoDesktop

    $configPath = Join-Path $codexHome "config.toml"
    $keyPath = Join-Path $codexHome "codex-lb-api-key"
    $config = [IO.File]::ReadAllText($configPath)

    Assert-True (([regex]::Matches($config, '(?m)^\[model_providers\.codex-lb\]\r?$')).Count -eq 1) "Provider block is not idempotent"
    Assert-True (([regex]::Matches($config, '(?m)^model = "gpt-5.6-luna"\r?$')).Count -eq 1) "Default model is incorrect"
    Assert-True ($config -match '(?m)^requires_openai_auth = false\r?$') "OpenAI login must not be required"
    Assert-True (([IO.File]::ReadAllText($keyPath)).Trim() -eq "test-secret") "Key file is incorrect"
    Assert-True ((Get-ChildItem -Path $codexHome -Filter "config.toml.backup-*" -File).Count -ge 1) "Config backup was not created"

    Write-Host "PowerShell installer self-test: OK"
} finally {
    $env:CODEX_HOME = $oldCodexHome
    $env:PATH = $oldPath
    $env:CODEX_LB_API_KEY = $oldProcessKey
    [Environment]::SetEnvironmentVariable("CODEX_LB_API_KEY", $oldUserKey, "User")
    Remove-Item Function:\Invoke-RestMethod -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -Recurse -Force -LiteralPath $testRoot
    }
}
