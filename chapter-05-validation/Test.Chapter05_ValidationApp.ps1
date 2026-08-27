# =============================================================================
# Test.Chapter05_ValidationApp.ps1 - Execution & Fail-Fast Output Validation Script
# Project: Chapter05_ValidationApp.dpr (Chapter 05)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter05_ValidationApp.exe"

Write-Host "[RUN] Executing Chapter05_ValidationApp.exe..." -ForegroundColor Yellow
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

if ($StdOut -notmatch "Validacao Declarativa por Atributos" -or $StdOut -notmatch "Validacao Fluente Avancada") {
    Write-Host "[FAIL] Expected validation stages output pattern not matched." -ForegroundColor Red
    $Success = $false
}

if ($StdOut -notmatch "Fail-Fast validation pipeline executed successfully") {
    Write-Host "[FAIL] Expected final pipeline success message not found." -ForegroundColor Red
    $Success = $false
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter05_ValidationApp attribute and fluent validation passed!     " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter05_ValidationApp execution validation failed.                " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
