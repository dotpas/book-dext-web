# =============================================================================
# Test.Chapter21_GrpcApp.ps1 - Execution & Protobuf Serialization Validation Script
# Project: Chapter21_GrpcApp.dpr (Chapter 21)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter21_GrpcApp.exe"

Write-Host "[RUN] Executing Chapter21_GrpcApp.exe (gRPC & Protobuf Round-Trip)..." -ForegroundColor Yellow
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

if ($StdOut -notmatch "contrato Protobuf, invocacao da RPC e round-trip de serializacao binaria validados com exito") {
    Write-Host "[FAIL] gRPC Protobuf round-trip execution pattern not matched." -ForegroundColor Red
    $Success = $false
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter21_GrpcApp Protobuf binary RPC execution validated!         " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter21_GrpcApp execution validation failed.                      " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
