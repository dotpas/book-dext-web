# =============================================================================
# Test.Chapter07_ControllerApp.ps1 - Controllers REST API Validation
# Project: Chapter07_ControllerApp.dpr (Chapter 07)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter07_ControllerApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter07_ControllerApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter07_ControllerApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. Test GET /api/v1/faturas
    Write-Host "`n[TEST 1] GET /api/v1/faturas?clienteId=42..." -ForegroundColor Yellow
    $Res1 = $HttpClient.GetAsync("$BaseUrl/api/v1/faturas?clienteId=42").Result
    $Body1 = $Res1.Content.ReadAsStringAsync().Result
    if ($Res1.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body1 -match "1500.50") {
        Write-Host "  [SUCCESS] HTTP 200 OK | Body: $Body1" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($Res1.StatusCode) | Body: $Body1" -ForegroundColor Red
        $Success = $false
    }

    # 2. Test GET /api/v1/faturas/105
    Write-Host "`n[TEST 2] GET /api/v1/faturas/105..." -ForegroundColor Yellow
    $Res2 = $HttpClient.GetAsync("$BaseUrl/api/v1/faturas/105").Result
    $Body2 = $Res2.Content.ReadAsStringAsync().Result
    if ($Res2.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body2 -match "105") {
        Write-Host "  [SUCCESS] HTTP 200 OK | Body: $Body2" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($Res2.StatusCode) | Body: $Body2" -ForegroundColor Red
        $Success = $false
    }

    # 3. Test DELETE /api/v1/faturas/105
    Write-Host "`n[TEST 3] DELETE /api/v1/faturas/105..." -ForegroundColor Yellow
    $Res3 = $HttpClient.DeleteAsync("$BaseUrl/api/v1/faturas/105").Result
    $Body3 = $Res3.Content.ReadAsStringAsync().Result
    if ($Res3.StatusCode -eq [System.Net.HttpStatusCode]::OK -or $Res3.StatusCode -eq [System.Net.HttpStatusCode]::NoContent) {
        Write-Host "  [SUCCESS] HTTP $($Res3.StatusCode) | Body: $Body3" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($Res3.StatusCode) | Body: $Body3" -ForegroundColor Red
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
        Write-Host "`n[CLEANUP] Chapter07_ControllerApp.exe process terminated (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter07_ControllerApp endpoints validated cleanly!               " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter07_ControllerApp endpoint validation failed.                " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
