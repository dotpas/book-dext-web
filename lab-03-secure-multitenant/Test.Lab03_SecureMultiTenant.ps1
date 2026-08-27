# =============================================================================
# Test.Lab03_SecureMultiTenant.ps1 - Secure Multi-Tenant Enterprise Core Validation
# Project: Lab03_SecureMultiTenant.dpr (Lab 03)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Lab03_SecureMultiTenant.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Lab03_SecureMultiTenant" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Lab03_SecureMultiTenant.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. Teste Não Autenticado -> 401
    Write-Host "`n[TEST 1] GET /api/v1/faturas sem token (Esperado 401 Unauthorized)..." -ForegroundColor Yellow
    $Resp1 = $HttpClient.GetAsync("$BaseUrl/api/v1/faturas").Result
    if ($Resp1.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
        Write-Host "  [SUCESSO] Retornou 401 Unauthorized." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 401, recebido: $($Resp1.StatusCode)" -ForegroundColor Red
        $Success = $false
    }

    # 2. Login Operador (Tenant Alfa)
    Write-Host "`n[TEST 2] POST /api/v1/auth/token?perfil=operador&tenant=tenant-alfa..." -ForegroundColor Yellow
    $RespDir = $HttpClient.PostAsync("$BaseUrl/api/v1/auth/token?perfil=diretoria&tenant=tenant-beta", $null).Result
    $RawDir = $RespDir.Content.ReadAsStringAsync().Result
    $BodyDir = $RawDir | ConvertFrom-Json
    if ($BodyDir.value) { $BodyDir = $BodyDir.value | ConvertFrom-Json }
    $TokenDir = $BodyDir.token
    
    $RespOp = $HttpClient.PostAsync("$BaseUrl/api/v1/auth/token?perfil=operador&tenant=tenant-alfa", $null).Result
    $RawOp = $RespOp.Content.ReadAsStringAsync().Result
    $BodyOp = $RawOp | ConvertFrom-Json
    if ($BodyOp.value) { $BodyOp = $BodyOp.value | ConvertFrom-Json }
    $TokenOp = $BodyOp.token

    # 3. Consulta com Tenant Alfa
    Write-Host "`n[TEST 3] GET /api/v1/faturas com Token Tenant Alfa..." -ForegroundColor Yellow
    $ReqGet = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, "$BaseUrl/api/v1/faturas")
    $ReqGet.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $TokenOp)
    $RespGet = $HttpClient.SendAsync($ReqGet).Result
    $BodyGet = $RespGet.Content.ReadAsStringAsync().Result
    if ($RespGet.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $BodyGet -match "tenant-alfa") {
        Write-Host "  [SUCESSO] Consulta retornou faturas do tenant-alfa com sucesso." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Falha na consulta por tenant: $BodyGet" -ForegroundColor Red
        $Success = $false
    }

    # 4. Cancelamento Bloqueado para Operador (403)
    Write-Host "`n[TEST 4] DELETE /api/v1/faturas/105 com Operador (Esperado 403 Forbidden)..." -ForegroundColor Yellow
    $ReqDelOp = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Delete, "$BaseUrl/api/v1/faturas/105")
    $ReqDelOp.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $TokenOp)
    $RespDelOp = $HttpClient.SendAsync($ReqDelOp).Result
    if ($RespDelOp.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden) {
        Write-Host "  [SUCESSO] Retornou 403 Forbidden por limite de alcada." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 403, recebido: $($RespDelOp.StatusCode)" -ForegroundColor Red
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
    Write-Host " SUCESSO: Laboratorio 3 aprovado em todos os requisitos de seguranca! " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA no Laboratorio 3.                                             " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
