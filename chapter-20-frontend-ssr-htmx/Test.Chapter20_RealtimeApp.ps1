# =============================================================================
# Test.Chapter20_RealtimeApp.ps1 - SSR Dext Templates & HTMX Validation
# Project: Chapter20_RealtimeApp.dpr (Chapter 20)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter20_RealtimeApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter20_RealtimeApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter20_RealtimeApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. GET / (Servir index.html de memória)
    Write-Host "`n[TEST 1] GET / (Index Page)..." -ForegroundColor Yellow
    $ResHome = $HttpClient.GetAsync("$BaseUrl/").Result
    $BodyHome = $ResHome.Content.ReadAsStringAsync().Result

    if ($ResHome.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $BodyHome -match "<html") {
        Write-Host "  [SUCCESS] HTTP 200 OK | HTML Page Served from Memory!" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResHome.StatusCode) | Body: $BodyHome" -ForegroundColor Red
        $Success = $false
    }

    # 2. GET /htmx/update-invoice (SSR & HTMX Fragment Response)
    Write-Host "`n[TEST 2] GET /htmx/update-invoice (HTMX HTML Fragment)..." -ForegroundColor Yellow
    $ResHtmx = $HttpClient.GetAsync("$BaseUrl/htmx/update-invoice").Result
    $BodyHtmx = $ResHtmx.Content.ReadAsStringAsync().Result

    if ($ResHtmx.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $BodyHtmx -match "Fatura INV-") {
        Write-Host "  [SUCCESS] HTTP 200 OK | HTMX Partial HTML Fragment Rendered: $BodyHtmx" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResHtmx.StatusCode) | Body: $BodyHtmx" -ForegroundColor Red
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
        Write-Host "`n[CLEANUP] Chapter20_RealtimeApp.exe process terminated (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter20_RealtimeApp SSR, HTMX and WebSocket Server Validated!     " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter20_RealtimeApp endpoint validation failed.                  " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
