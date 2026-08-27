# =============================================================================
# build_and_test_all_examples.ps1 - Master Build + Test Runner for Dext Book
# Location: Docs/dext-developer-bookshelf/book/examples/build_and_test_all_examples.ps1
# =============================================================================

$ErrorActionPreference = "Continue"
$ExamplesDir = $PSScriptRoot

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "       Dext Book Examples: Master Build + Test Pipeline            " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan

# 1. Step 1: Compile all projects cleanly
Write-Host "`n[FASE 1/2] Compilando todos os 29 projetos de exemplos..." -ForegroundColor Yellow
$CompileScript = Join-Path $ExamplesDir "compile_all_examples.ps1"

$CompileProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$CompileScript`"" -NoNewWindow -PassThru -Wait

if ($CompileProcess.ExitCode -ne 0) {
    Write-Host "`n[ERRO CRITICO] A compilacao de projetos falhou. Abortando testes." -ForegroundColor Red
    exit 1
}

# 2. Step 2: Run all test scripts
Write-Host "`n[FASE 2/2] Executando scripts de testes e validacao de endpoints..." -ForegroundColor Yellow
$TestScript = Join-Path $ExamplesDir "test_all_examples.ps1"

$TestProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$TestScript`"" -NoNewWindow -PassThru -Wait

if ($TestProcess.ExitCode -ne 0) {
    Write-Host "`n[ERRO CRITICO] A validacao de testes falhou." -ForegroundColor Red
    exit 1
}

Write-Host "`n====================================================================" -ForegroundColor Green
Write-Host " SUCESSO TOTAL: 29/29 projetos compilados e testados com 0 falhas!  " -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
exit 0
