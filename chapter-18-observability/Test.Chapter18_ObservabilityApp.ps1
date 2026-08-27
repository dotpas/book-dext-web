# =============================================================================
# Test.Chapter18_ObservabilityApp.ps1 - Observability, Health Checks & Metrics
# Project: Chapter18_ObservabilityApp.dpr (Chapter 18)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter18_ObservabilityApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter18_ObservabilityApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter18_ObservabilityApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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

try {
    # 1. GET /health/live (Liveness Probe)
    Write-Host "`n[TEST 1] GET /health/live (Liveness Probe)..." -ForegroundColor Yellow
    $ResLive = $HttpClient.GetAsync("$BaseUrl/health/live").Result
    $BodyLive = $ResLive.Content.ReadAsStringAsync().Result

    if ($ResLive.StatusCode -eq [System.Net.HttpStatusCode]::OK -and ($BodyLive -match "UP" -or $BodyLive -match "Healthy")) {
        Write-Host "  [SUCCESS] HTTP 200 OK | Liveness Probe UP: $BodyLive" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResLive.StatusCode) | Body: $BodyLive" -ForegroundColor Red
        $Success = $false
    }

    # 2. GET /health/ready (Readiness Probe SQLite Connection)
    Write-Host "`n[TEST 2] GET /health/ready (Readiness Probe SQLite)..." -ForegroundColor Yellow
    $ResReady = $HttpClient.GetAsync("$BaseUrl/health/ready").Result
    $BodyReady = $ResReady.Content.ReadAsStringAsync().Result

    if ($ResReady.StatusCode -eq [System.Net.HttpStatusCode]::OK -and ($BodyReady -match "READY" -or $BodyReady -match "Healthy")) {
        Write-Host "  [SUCCESS] HTTP 200 OK | Readiness Probe READY: $BodyReady" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResReady.StatusCode) | Body: $BodyReady" -ForegroundColor Red
        $Success = $false
    }

    # 3. GET /metrics (Prometheus Metrics Endpoint)
    Write-Host "`n[TEST 3] GET /metrics (Prometheus Metrics)..." -ForegroundColor Yellow
    $ResMetrics = $HttpClient.GetAsync("$BaseUrl/metrics").Result
    $BodyMetrics = $ResMetrics.Content.ReadAsStringAsync().Result

    if ($ResMetrics.StatusCode -eq [System.Net.HttpStatusCode]::OK -and ($BodyMetrics -match "metrics" -or $BodyMetrics -match "total_requests")) {
        Write-Host "  [SUCCESS] HTTP 200 OK | Prometheus Metrics Exported: $BodyMetrics" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResMetrics.StatusCode) | Body: $BodyMetrics" -ForegroundColor Red
        $Success = $false
    }
}
catch {
    Write-Host "  [EXCEPTION] $($_.Exception.Message)" -ForegroundColor Red
    $Success = $false
}
finally {
    if ($HttpClient) { $HttpClient.Dispose() }
    if ($Process -and -not $Process.HasExited -and $AutoClose -and -not $WasAlreadyRunning) {
        $Process.Kill()
        Write-Host "`n[CLEANUP] Chapter18_ObservabilityApp.exe process terminated (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter18_ObservabilityApp Probes and Observability Validated Cleanly!   " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter18_ObservabilityApp endpoint validation failed.                   " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
