# =============================================================================
# Test.Chapter14_SecurityJwtApp.ps1 - JWT Authentication & Security Validation
# Project: Chapter14_SecurityJwtApp.dpr (Chapter 14)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter14_SecurityJwtApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter14_SecurityJwtApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter14_SecurityJwtApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. POST /api/v1/auth/login (Obter JWT Token)
    Write-Host "`n[TEST 1] POST /api/v1/auth/login (Authenticating admin credentials)..." -ForegroundColor Yellow
    $LoginBody = '{"username":"admin","password":"AdminSecret2026!"}'
    $Content = New-Object System.Net.Http.StringContent($LoginBody, [System.Text.Encoding]::UTF8, "application/json")
    $ResLogin = $HttpClient.PostAsync("$BaseUrl/api/v1/auth/login", $Content).Result
    $BodyLogin = $ResLogin.Content.ReadAsStringAsync().Result

    $Token = ""
    if ($ResLogin.StatusCode -eq [System.Net.HttpStatusCode]::OK) {
        $JsonObj = $BodyLogin | ConvertFrom-Json
        if ($JsonObj.value) {
            $InnerObj = $JsonObj.value | ConvertFrom-Json
            $Token = $InnerObj.token
        } else {
            $Token = $JsonObj.token
        }
        Write-Host "  [SUCCESS] HTTP 200 OK | Token Issued Successfully: $Token" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($ResLogin.StatusCode) | Body: $BodyLogin" -ForegroundColor Red
        $Success = $false
    }

    # 2. GET /api/v1/protected/admin Sem Token (Expect 401 Unauthorized)
    Write-Host "`n[TEST 2] GET /api/v1/protected/admin Without Bearer Token..." -ForegroundColor Yellow
    $ResNoToken = $HttpClient.GetAsync("$BaseUrl/api/v1/protected/admin").Result
    if ($ResNoToken.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
        Write-Host "  [SUCCESS] HTTP 401 Unauthorized (Access denied as expected)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Expected HTTP 401 Unauthorized, got $($ResNoToken.StatusCode)" -ForegroundColor Red
        $Success = $false
    }

    # 3. GET /api/v1/protected/admin Com Token JWT Bearer
    if ($Token -ne "") {
        Write-Host "`n[TEST 3] GET /api/v1/protected/admin With Valid JWT Bearer Token..." -ForegroundColor Yellow
        $ReqAuth = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, "$BaseUrl/api/v1/protected/admin")
        $ReqAuth.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $Token)
        $ResAuth = $HttpClient.SendAsync($ReqAuth).Result
        $BodyAuth = $ResAuth.Content.ReadAsStringAsync().Result

        if ($ResAuth.StatusCode -eq [System.Net.HttpStatusCode]::OK) {
            Write-Host "  [SUCCESS] HTTP 200 OK | Body: $BodyAuth" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Expected HTTP 200 OK, got $($ResAuth.StatusCode) | Body: $BodyAuth" -ForegroundColor Red
            $Success = $false
        }
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
        Write-Host "`n[CLEANUP] Chapter14_SecurityJwtApp.exe process terminated (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter14_SecurityJwtApp JWT Auth and Protected Endpoints Validated!  " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter14_SecurityJwtApp endpoint validation failed.                  " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
