# =============================================================================
# Test.Chapter19_SwaggerApp.ps1 - Swagger UI & OpenAPI Specification Validation
# Project: Chapter19_SwaggerApp.dpr (Chapter 19)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter19_SwaggerApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter19_SwaggerApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter19_SwaggerApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. GET /swagger.json
    Write-Host "`n[TEST 1] GET /swagger.json..." -ForegroundColor Yellow
    $ResJson = $HttpClient.GetAsync("$BaseUrl/swagger.json").Result
    $BodyJson = $ResJson.Content.ReadAsStringAsync().Result

    if ($ResJson.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $BodyJson -match "openapi") {
        Write-Host "  [SUCCESS] HTTP 200 OK | OpenAPI 3.0 JSON Spec Validated!" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResJson.StatusCode) | Body: $BodyJson" -ForegroundColor Red
        $Success = $false
    }

    # 2. GET /swagger (Swagger UI Interface)
    Write-Host "`n[TEST 2] GET /swagger (Swagger UI Interface)..." -ForegroundColor Yellow
    $ResUi = $HttpClient.GetAsync("$BaseUrl/swagger").Result
    $BodyUi = $ResUi.Content.ReadAsStringAsync().Result

    if ($ResUi.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $BodyUi -match "swagger-ui") {
        Write-Host "  [SUCCESS] HTTP 200 OK | Swagger UI Web Page Rendered!" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResUi.StatusCode) | Body: $BodyUi" -ForegroundColor Red
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
        Write-Host "`n[CLEANUP] Chapter19_SwaggerApp.exe process terminated (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter19_SwaggerApp OpenAPI Spec and UI Interface Validated!       " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter19_SwaggerApp endpoint validation failed.                   " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
