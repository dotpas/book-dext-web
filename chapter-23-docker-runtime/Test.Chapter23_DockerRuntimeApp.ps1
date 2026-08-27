# =============================================================================
# Test.Chapter23_DockerRuntimeApp.ps1 - Docker Runtime Daemon Validation
# Project: Chapter23_DockerRuntimeApp.dpr (Chapter 23)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter23_DockerRuntimeApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter23_DockerRuntimeApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter23_DockerRuntimeApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. Teste de Liveness Probe
    Write-Host "`n[TEST 1] GET /healthz/live (Docker Liveness Probe)..." -ForegroundColor Yellow
    $Resp1 = $HttpClient.GetAsync("$BaseUrl/healthz/live").Result
    $Body1 = $Resp1.Content.ReadAsStringAsync().Result
    if ($Resp1.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body1 -match "Healthy") {
        Write-Host "  [SUCESSO] Liveness Probe OK: $Body1" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Resposta inesperada: $Body1" -ForegroundColor Red
        $Success = $false
    }

    # 2. Teste de Readiness Probe
    Write-Host "`n[TEST 2] GET /healthz/ready (Docker Readiness Probe)..." -ForegroundColor Yellow
    $Resp2 = $HttpClient.GetAsync("$BaseUrl/healthz/ready").Result
    $Body2 = $Resp2.Content.ReadAsStringAsync().Result
    if ($Resp2.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body2 -match "Ready") {
        Write-Host "  [SUCESSO] Readiness Probe OK: $Body2" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Resposta inesperada: $Body2" -ForegroundColor Red
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
    Write-Host " SUCESSO: Servidor de Runtime Conteinerizavel validado com exito!     " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA no servidor de runtime Docker.                                " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
