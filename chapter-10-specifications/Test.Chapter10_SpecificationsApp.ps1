# =============================================================================
# Test.Chapter10_SpecificationsApp.ps1 - Specifications & Fluent Queries Validation
# Project: Chapter10_SpecificationsApp.dpr (Chapter 10)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter10_SpecificationsApp.exe"

if (-not (Test-Path $ExePath)) {
    Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
    Write-Host "        Compile o projeto Chapter10_SpecificationsApp.dpr antes de rodar os testes." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[TEST] Executando demonstracao de Specification Pattern..." -ForegroundColor Yellow
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

Write-Host $StdOut -ForegroundColor DarkGray

if ($Process.ExitCode -eq 0 -and $StdOut -match "\[SUCESSO\]") {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCESSO: Specification Pattern validado com exito!                  " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA: Ocorreu erro durante o teste de Specification Pattern.       " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    if ($StdErr) { Write-Host $StdErr -ForegroundColor Red }
    exit 1
}
