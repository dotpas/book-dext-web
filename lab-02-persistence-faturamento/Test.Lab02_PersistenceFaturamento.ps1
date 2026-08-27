# =============================================================================
# Test.Lab02_PersistenceFaturamento.ps1 - Invoicing Persistence & Keyset Validation
# Project: Lab02_PersistenceFaturamento.dpr (Lab 02)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Lab02_PersistenceFaturamento.exe"

if (-not (Test-Path $ExePath)) {
    Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
    Write-Host "        Compile o projeto Lab02_PersistenceFaturamento.dpr antes de rodar os testes." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[TEST] Executando demonstracao do Laboratorio 2..." -ForegroundColor Yellow
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
    Write-Host " SUCESSO: Laboratorio 2 executou e validou todos os testes!          " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA: Ocorreu erro durante o teste do Laboratorio 2.               " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    if ($StdErr) { Write-Host $StdErr -ForegroundColor Red }
    exit 1
}
