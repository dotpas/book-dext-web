# =============================================================================
# Test.Lab05_EnterpriseFinal.ps1 - Multi-Channel Enterprise App Validation
# Project: Lab05_EnterpriseFinal.dpr (Lab 05)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Lab05_EnterpriseFinal.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Lab05_EnterpriseFinal" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Lab05_EnterpriseFinal.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. Teste da Home Page SSR / HTML
    Write-Host "`n[TEST 1] GET / (Validando Frontend SSR)..." -ForegroundColor Yellow
    $Resp1 = $HttpClient.GetAsync("$BaseUrl/").Result
    $Body1 = $Resp1.Content.ReadAsStringAsync().Result
    if ($Resp1.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body1 -match "Painel de Faturamento Dext") {
        Write-Host "  [SUCESSO] Frontend SSR respondeu com HTML valido." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Resposta inesperada: $Body1" -ForegroundColor Red
        $Success = $false
    }

    # 2. Teste da API de Faturas
    Write-Host "`n[TEST 2] GET /api/v1/faturas..." -ForegroundColor Yellow
    $Resp2 = $HttpClient.GetAsync("$BaseUrl/api/v1/faturas").Result
    $Body2 = $Resp2.Content.ReadAsStringAsync().Result
    if ($Resp2.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body2 -match "Empresa Alpha") {
        Write-Host "  [SUCESSO] API RESTful respondeu com JSON integro!" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Falha na API de faturas: $Body2" -ForegroundColor Red
        $Success = $false
    }
}
catch {
    Write-Host "  [FALHA] Erro de conexao: $($_.Exception.Message)" -ForegroundColor Red
    $Success = $false
}
finally {
    if ($HttpClient) { $HttpClient.Dispose() }
    if ($Process -and -not $Process.HasExited -and $AutoClose -and -not $WasAlreadyRunning) {
        $Process.Kill()
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCESSO: Laboratorio 5 Final aprovado em todos os testes ponta a ponta! " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA no Laboratorio 5.                                             " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
