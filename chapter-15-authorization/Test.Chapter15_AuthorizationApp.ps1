# =============================================================================
# Test.Chapter15_AuthorizationApp.ps1 - Role & Resource Authorization Validation
# Project: Chapter15_AuthorizationApp.dpr (Chapter 15)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter15_AuthorizationApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter15_AuthorizationApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter15_AuthorizationApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
        Write-Host "  [SUCESSO] Retornou 401 Unauthorized conforme esperado." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 401, recebido: $($Resp1.StatusCode)" -ForegroundColor Red
        $Success = $false
    }

    # 2. Obter Token de Operador (Alçada R$ 1.000)
    Write-Host "`n[TEST 2] POST /api/v1/auth/token?perfil=operador..." -ForegroundColor Yellow
    $RespOp = $HttpClient.PostAsync("$BaseUrl/api/v1/auth/token?perfil=operador", $null).Result
    $RawOp = $RespOp.Content.ReadAsStringAsync().Result
    $BodyOp = $RawOp | ConvertFrom-Json
    if ($BodyOp.value) { $BodyOp = $BodyOp.value | ConvertFrom-Json }
    $TokenOp = $BodyOp.token

    # 3. Cancelar com Operador -> 403 Forbidden
    Write-Host "`n[TEST 3] DELETE /api/v1/faturas/105 com Token de Operador (Esperado 403 Forbidden)..." -ForegroundColor Yellow
    $ReqDeleteOp = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Delete, "$BaseUrl/api/v1/faturas/105")
    $ReqDeleteOp.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $TokenOp)
    $RespDeleteOp = $HttpClient.SendAsync($ReqDeleteOp).Result
    if ($RespDeleteOp.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden) {
        Write-Host "  [SUCESSO] Retornou 403 Forbidden por restricao de alcada." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 403, recebido: $($RespDeleteOp.StatusCode)" -ForegroundColor Red
        $Success = $false
    }

    # 4. Obter Token de Diretoria (Alçada R$ 50.000)
    Write-Host "`n[TEST 4] POST /api/v1/auth/token?perfil=diretoria..." -ForegroundColor Yellow
    $RespDir = $HttpClient.PostAsync("$BaseUrl/api/v1/auth/token?perfil=diretoria", $null).Result
    $RawDir = $RespDir.Content.ReadAsStringAsync().Result
    $BodyDir = $RawDir | ConvertFrom-Json
    if ($BodyDir.value) { $BodyDir = $BodyDir.value | ConvertFrom-Json }
    $TokenDir = $BodyDir.token

    # 5. Cancelar com Diretoria -> 204 No Content
    Write-Host "`n[TEST 5] DELETE /api/v1/faturas/105 com Token de Diretoria (Esperado 204 No Content)..." -ForegroundColor Yellow
    $ReqDeleteDir = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Delete, "$BaseUrl/api/v1/faturas/105")
    $ReqDeleteDir.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $TokenDir)
    $RespDeleteDir = $HttpClient.SendAsync($ReqDeleteDir).Result
    if ($RespDeleteDir.StatusCode -eq [System.Net.HttpStatusCode]::NoContent) {
        Write-Host "  [SUCESSO] Retornou 204 NoContent - Cancelamento autorizado!" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 204, recebido: $($RespDeleteDir.StatusCode)" -ForegroundColor Red
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
    Write-Host " SUCESSO: Todas as politicas e codigos 401/403 validados com exito!   " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA na suite de autorizacao.                                      " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
