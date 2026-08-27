# =============================================================================
# Test.Chapter12_MultiTenancyApp.ps1 - ORM & Multi-Tenancy Execution Validation Script
# Project: Chapter12_MultiTenancyApp.dpr (Chapter 12)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter12_MultiTenancyApp.exe"

Write-Host "[RUN] Executing Chapter12_MultiTenancyApp.exe (SQLite In-Memory + Multi-Tenancy)..." -ForegroundColor Yellow
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

if ($StdOut -notmatch "Isolamento de consultas no ORM .* verificados com exito") {
    Write-Host "[FAIL] Multi-Tenancy ORM query isolation pattern not matched." -ForegroundColor Red
    $Success = $false
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter12_MultiTenancyApp ORM & Multi-Tenancy isolation validated!       " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter12_MultiTenancyApp execution validation failed.                    " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
