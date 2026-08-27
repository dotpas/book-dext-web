# =============================================================================
# Test.Chapter17_ResilienceApp.ps1 - Circuit Breaker & Concurrency Validation
# Project: Chapter17_ResilienceApp.dpr (Chapter 17)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch,
    [switch]$KeepRunning
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter17_ResilienceApp.exe"
$DprPath = Join-Path $ScriptDir "Chapter17_ResilienceApp.dpr"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "       Validacao Automatizada do Exemplo - Capitulo 17 (Resiliencia)       " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan

# Executa o binário compilado
if (-not (Test-Path $ExePath)) {
    Write-Host "[ERRO] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
    exit 1
}

Write-Host "[EXECUCAO] Rodando $ExePath..." -ForegroundColor Yellow
$Output = & $ExePath
Write-Host $Output -ForegroundColor Gray

if ($Output -match "Disjuntor ABERTO detectado instantaneamente" -and $Output -match "TRestClient configurado com Retry") {
    Write-Host "`n[SUCESSO] Todas as assercoes de resiliencia e TRestClient foram validadas com exito!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FALHA] A saida do teste nao continha os padroes esperados." -ForegroundColor Red
    exit 1
}
