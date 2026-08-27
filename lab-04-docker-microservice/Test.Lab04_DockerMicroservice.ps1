# =============================================================================
# Test.Lab04_DockerMicroservice.ps1 - Observable Microservice Validation
# Project: Lab04_DockerMicroservice.dpr (Lab 04)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Lab04_DockerMicroservice.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Lab04_DockerMicroservice" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Lab04_DockerMicroservice.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. Teste de Health Check Probe
    Write-Host "`n[TEST 1] GET /health..." -ForegroundColor Yellow
    $Resp1 = $HttpClient.GetAsync("$BaseUrl/health").Result
    $Body1 = $Resp1.Content.ReadAsStringAsync().Result
    if ($Resp1.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body1 -match "Healthy") {
        Write-Host "  [SUCESSO] Health Probe OK: $Body1" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Resposta inesperada: $Body1" -ForegroundColor Red
        $Success = $false
    }

    # 2. Teste de Liveness Probe
    Write-Host "`n[TEST 2] GET /health/live..." -ForegroundColor Yellow
    $Resp2 = $HttpClient.GetAsync("$BaseUrl/health/live").Result
    $Body2 = $Resp2.Content.ReadAsStringAsync().Result
    if ($Resp2.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body2 -match "Healthy") {
        Write-Host "  [SUCESSO] Liveness Probe OK (/health/live): $Body2" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Resposta inesperada: $Body2" -ForegroundColor Red
        $Success = $false
    }

    Write-Host "`n[TEST 2.1] GET /healthz/live..." -ForegroundColor Yellow
    $Resp21 = $HttpClient.GetAsync("$BaseUrl/healthz/live").Result
    $Body21 = $Resp21.Content.ReadAsStringAsync().Result
    if ($Resp21.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body21 -match "Healthy") {
        Write-Host "  [SUCESSO] Liveness Probe Alias OK (/healthz/live): $Body21" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Resposta inesperada: $Body21" -ForegroundColor Red
        $Success = $false
    }

    # 3. Teste de Readiness Probe
    Write-Host "`n[TEST 3] GET /health/ready..." -ForegroundColor Yellow
    $Resp3 = $HttpClient.GetAsync("$BaseUrl/health/ready").Result
    $Body3 = $Resp3.Content.ReadAsStringAsync().Result
    if ($Resp3.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body3 -match "Ready") {
        Write-Host "  [SUCESSO] Readiness Probe OK (/health/ready): $Body3" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Resposta inesperada: $Body3" -ForegroundColor Red
        $Success = $false
    }

    Write-Host "`n[TEST 3.1] GET /healthz/ready..." -ForegroundColor Yellow
    $Resp31 = $HttpClient.GetAsync("$BaseUrl/healthz/ready").Result
    $Body31 = $Resp31.Content.ReadAsStringAsync().Result
    if ($Resp31.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body31 -match "Ready") {
        Write-Host "  [SUCESSO] Readiness Probe Alias OK (/healthz/ready): $Body31" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Resposta inesperada: $Body31" -ForegroundColor Red
        $Success = $false
    }

    # 4. Teste de Contrato OpenAPI (Swagger JSON)
    Write-Host "`n[TEST 4] GET /swagger.json..." -ForegroundColor Yellow
    $Resp4 = $HttpClient.GetAsync("$BaseUrl/swagger.json").Result
    $Body4 = $Resp4.Content.ReadAsStringAsync().Result
    if ($Resp4.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body4 -match "openapi") {
        Write-Host "  [SUCESSO] Contrato OpenAPI retornado com exito!" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Falha no contrato OpenAPI: $Body4" -ForegroundColor Red
        $Success = $false
    }

    # 5. Teste de Métricas Prometheus
    Write-Host "`n[TEST 5] GET /metrics..." -ForegroundColor Yellow
    $Resp5 = $HttpClient.GetAsync("$BaseUrl/metrics").Result
    $Body5 = $Resp5.Content.ReadAsStringAsync().Result
    if ($Resp5.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body5 -match "http_requests_total") {
        Write-Host "  [SUCESSO] Metricas Prometheus retornadas com exito!" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Falha nas metricas: $Body5" -ForegroundColor Red
        $Success = $false
    }

    # 6. Teste de API REST de Faturas
    Write-Host "`n[TEST 6] GET /api/v1/faturas..." -ForegroundColor Yellow
    $Resp6 = $HttpClient.GetAsync("$BaseUrl/api/v1/faturas").Result
    $Body6 = $Resp6.Content.ReadAsStringAsync().Result
    if ($Resp6.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body6 -match "faturas") {
        Write-Host "  [SUCESSO] Endpoint /api/v1/faturas retornado com exito: $Body6" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Falha no endpoint de faturas: $Body6" -ForegroundColor Red
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
    Write-Host " SUCESSO: Laboratorio 4 aprovado em observabilidade e monitoramento!  " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA no Laboratorio 4.                                             " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
