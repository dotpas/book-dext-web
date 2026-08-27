# =============================================================================
# Test.Chapter01_FirstAPI.ps1 - Minimal HTTP Server Endpoint Validation
# Project: Chapter01_FirstAPI.dpr (Chapter 01)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter01_FirstAPI.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter01_FirstAPI" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter01_FirstAPI.dpr antes de rodar os testes." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "[LAUNCH] Iniciando $ExePath em segundo plano..." -ForegroundColor Yellow
    $PInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = $ExePath
        WorkingDirectory = $ScriptDir
        UseShellExecute = $false
        CreateNoWindow = $true
    }
    $Process = [System.Diagnostics.Process]::Start($PInfo)
    Start-Sleep -Seconds 2
} else {
    Write-Host "[ERROR] O servidor nao esta em execucao e o parametro -NoAutoLaunch foi informado." -ForegroundColor Red
    exit 1
}

$Success = $true
$HttpClient = New-Object System.Net.Http.HttpClient
$HttpClient.Timeout = [TimeSpan]::FromSeconds(5)

try {
    Write-Host "`n[TEST] GET / (Validando endpoint raiz)..." -ForegroundColor Yellow
    $Response = $HttpClient.GetAsync("$BaseUrl/").Result
    $Body = $Response.Content.ReadAsStringAsync().Result
    
    if ($Response.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body -match "Olá, Dext Web!") {
        Write-Host "  [SUCESSO] HTTP 200 OK | Resposta: $Body" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] HTTP $($Response.StatusCode) | Resposta: $Body" -ForegroundColor Red
        $Success = $false
    }
}
catch {
    Write-Host "  [FALHA] Nao foi possivel conectar ao servidor: $($_.Exception.Message)" -ForegroundColor Red
    $Success = $false
}
finally {
    if ($HttpClient) { $HttpClient.Dispose() }

    # Encerra o processo apenas se:
    # 1. Foi iniciado por este script
    # 2. Foi passado explicitamente o parametro -AutoClose (ex: suite automatizada de CI)
    if ($Process -and -not $Process.HasExited -and $AutoClose -and -not $WasAlreadyRunning) {
        $Process.Kill()
        Write-Host "`n[CLEANUP] Processo de teste encerrado (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCESSO: Todos os endpoints responderam conforme o esperado!       " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA: O servidor nao respondeu corretamente aos testes.           " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
