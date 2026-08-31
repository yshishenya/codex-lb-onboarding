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
$oldProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
$oldProcessorArchitectureWow = $env:PROCESSOR_ARCHITEW6432

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$tokens = $null
$errors = $null
$installerAst = [System.Management.Automation.Language.Parser]::ParseFile($installer, [ref]$tokens, [ref]$errors)
$compatibilityFunction = $installerAst.Find({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq "Add-WindowsPowerShellArchitectureCompatibility"
}, $true)
Assert-True ($null -ne $compatibilityFunction) "Architecture compatibility function was not found"
. ([scriptblock]::Create($compatibilityFunction.Extent.Text))

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
    $runtimeProbe = '$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture'
    $patchedProbe = Add-WindowsPowerShellArchitectureCompatibility $runtimeProbe
    Assert-True (-not $patchedProbe.Contains($runtimeProbe)) "RuntimeInformation OSArchitecture probe was not replaced"

    $env:PROCESSOR_ARCHITEW6432 = $null
    $env:PROCESSOR_ARCHITECTURE = "ARM64"
    $armArchitecture = & { param($source) . ([scriptblock]::Create($source)); $architecture } $patchedProbe
    Assert-True ($armArchitecture -eq "Arm64") "ARM64 compatibility mapping is incorrect"

    $env:PROCESSOR_ARCHITECTURE = "AMD64"
    $x64Architecture = & { param($source) . ([scriptblock]::Create($source)); $architecture } $patchedProbe
    Assert-True ($x64Architecture -eq "X64") "x64 compatibility mapping is incorrect"

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
    $env:PROCESSOR_ARCHITECTURE = $oldProcessorArchitecture
    $env:PROCESSOR_ARCHITEW6432 = $oldProcessorArchitectureWow
    [Environment]::SetEnvironmentVariable("CODEX_LB_API_KEY", $oldUserKey, "User")
    Remove-Item Function:\Invoke-RestMethod -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -Recurse -Force -LiteralPath $testRoot
    }
}
