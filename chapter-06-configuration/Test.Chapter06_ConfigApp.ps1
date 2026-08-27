# =============================================================================
# Test.Chapter06_ConfigApp.ps1 - Configuration Hierarchy & Feature Flags Validation
# Project: Chapter06_ConfigApp.dpr (Chapter 06)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter06_ConfigApp.exe"

Write-Host "[RUN] Executing Chapter06_ConfigApp.exe..." -ForegroundColor Yellow
$PInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
    FileName = $ExePath
    WorkingDirectory = $ScriptDir
    UseShellExecute = $false
    RedirectStandardOutput = $true
    RedirectStandardError = $true
    CreateNoWindow = $true
}

$Process = [System.Diagnostics.Process]::Start($PInfo)
$StdOut = $Process.StandardOutput.ReadToEnd()
$StdErr = $Process.StandardError.ReadToEnd()
$Process.WaitForExit()

Write-Host "`n--- Execution Output ---" -ForegroundColor Gray
Write-Host $StdOut -ForegroundColor White

$Success = $true
if ($Process.ExitCode -ne 0) {
    Write-Host "[FAIL] Process exited with code $($Process.ExitCode)" -ForegroundColor Red
    $Success = $false
}

if ($StdOut -notmatch "Porta lida do YAML:") {
    Write-Host "[FAIL] Expected YAML configuration output pattern not matched." -ForegroundColor Red
    $Success = $false
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter06_ConfigApp configuration reading validation passed!       " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter06_ConfigApp execution validation failed.                    " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
