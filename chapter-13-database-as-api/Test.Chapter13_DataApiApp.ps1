# =============================================================================
# Test.Chapter13_DataApiApp.ps1 - Database-as-API & Governance Validation
# Project: Chapter13_DataApiApp.dpr (Chapter 13)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter13_DataApiApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter13_DataApiApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter13_DataApiApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. GET /api/v1/customers (Autorizado)
    Write-Host "`n[TEST 1] GET /api/v1/customers (Allowed Verb)..." -ForegroundColor Yellow
    $ResGet = $HttpClient.GetAsync("$BaseUrl/api/v1/customers").Result
    $BodyGet = $ResGet.Content.ReadAsStringAsync().Result
    if ($ResGet.StatusCode -eq [System.Net.HttpStatusCode]::OK) {
        Write-Host "  [SUCCESS] HTTP 200 OK | Body: $BodyGet" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResGet.StatusCode) | Body: $BodyGet" -ForegroundColor Red
        $Success = $false
    }

    # 2. DELETE /api/v1/customers/1 (Bloqueado por Allowlist)
    Write-Host "`n[TEST 2] DELETE /api/v1/customers/1 (Forbidden Verb)..." -ForegroundColor Yellow
    $ReqDelete = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Delete, "$BaseUrl/api/v1/customers/1")
    $ResDelete = $HttpClient.SendAsync($ReqDelete).Result
    if ($ResDelete.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden) {
        Write-Host "  [SUCCESS] HTTP 403 Forbidden (Blocked by Allowlist as expected)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Expected HTTP 403 Forbidden, got $($ResDelete.StatusCode)" -ForegroundColor Red
        $Success = $false
    }

    # 3. GET /api/v1/customers?limit=500 (Exceeds Max Limit)
    Write-Host "`n[TEST 3] GET /api/v1/customers?limit=500 (Max Limit Exceeded)..." -ForegroundColor Yellow
    $ResLimit = $HttpClient.GetAsync("$BaseUrl/api/v1/customers?limit=500").Result
    if ($ResLimit.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
        Write-Host "  [SUCCESS] HTTP 400 Bad Request (Limit boundary enforced as expected)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Expected HTTP 400 Bad Request, got $($ResLimit.StatusCode)" -ForegroundColor Red
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
        Write-Host "`n[CLEANUP] Chapter13_DataApiApp.exe process terminated (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter13_DataApiApp security allowlist and pagination validated!   " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter13_DataApiApp endpoint validation failed.                   " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
