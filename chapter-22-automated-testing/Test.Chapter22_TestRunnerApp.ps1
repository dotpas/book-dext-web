# =============================================================================
# Test.Chapter22_TestRunnerApp.ps1 - Automated Test Suite Runner Execution Validation
# Project: Chapter22_TestRunnerApp.dpr (Chapter 22)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter22_TestRunnerApp.exe"

Write-Host "[RUN] Executing Chapter22_TestRunnerApp.exe (Dext Testing Suite)..." -ForegroundColor Yellow
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
    Write-Host "[FAIL] Test suite execution failed with exit code $($Process.ExitCode)" -ForegroundColor Red
    $Success = $false
}

if ($StdOut -notmatch "Todos os testes passaram com sucesso") {
    Write-Host "[FAIL] Test suite summary pattern not matched." -ForegroundColor Red
    $Success = $false
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter22_TestRunnerApp unit test suite executed cleanly!          " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter22_TestRunnerApp test suite execution failed.                " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
