# =============================================================================
# Test.Chapter11_DomainCqrsApp.ps1 - Domain CQRS & Event Sourcing Validation
# Project: Chapter11_DomainCqrsApp.dpr (Chapter 11)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter11_DomainCqrsApp.exe"

if (-not (Test-Path $ExePath)) {
    Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
    Write-Host "        Compile o projeto Chapter11_DomainCqrsApp.dpr antes de rodar os testes." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[TEST] Executando demonstracao de Domain Model e CQRS..." -ForegroundColor Yellow
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
    Write-Host " SUCESSO: Domain Model Rico e CQRS validados com exito!              " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA: Ocorreu erro durante o teste de Domain Model CQRS.           " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    if ($StdErr) { Write-Host $StdErr -ForegroundColor Red }
    exit 1
}
