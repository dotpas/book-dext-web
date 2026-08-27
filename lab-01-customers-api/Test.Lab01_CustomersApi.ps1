# =============================================================================
# Test.Lab01_CustomersApi.ps1 - Customers API Microservice Validation
# Project: Lab01_CustomersApi.dpr (Lab 01)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch,
    [switch]$KeepRunning
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Lab01_CustomersApi.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Lab01_CustomersApi" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} else {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Lab01_CustomersApi.dpr antes de rodar os testes." -ForegroundColor Yellow
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
}

$Success = $true
$HttpClient = New-Object System.Net.Http.HttpClient
$HttpClient.Timeout = [TimeSpan]::FromSeconds(5)

try {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "   Executando Testes de Integracao - Laboratorio 1      " -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    # 1. Teste: POST /api/v1/clientes com payload válido (201 Created)
    Write-Host "`n[TEST 1] POST /api/v1/clientes (Cadastro Valido -> 201 Created)..." -ForegroundColor Yellow
    $ValidJson = '{"name": "Tech Solutions LTDA", "email": "contato@tech.com", "documentNumber": "12345678000199", "creditLimit": 5000.00}'
    $Content = New-Object System.Net.Http.StringContent($ValidJson, [System.Text.Encoding]::UTF8, "application/json")
    $Resp1 = $HttpClient.PostAsync("$BaseUrl/api/v1/clientes", $Content).Result
    $Body1 = $Resp1.Content.ReadAsStringAsync().Result
    
    if ($Resp1.StatusCode -eq [System.Net.HttpStatusCode]::Created -and $Body1 -match "Tech Solutions LTDA") {
        Write-Host "  [SUCESSO] HTTP 201 Created" -ForegroundColor Green
        Write-Host "            Body: $Body1" -ForegroundColor Gray
    } else {
        Write-Host "  [FALHA] Esperado 201 Created. Recebido: $($Resp1.StatusCode)" -ForegroundColor Red
        Write-Host "          Body: $Body1" -ForegroundColor Red
        $Success = $false
    }

    # 2. Teste: POST /api/v1/clientes com payload inválido (400 Bad Request + Problem Details)
    Write-Host "`n[TEST 2] POST /api/v1/clientes (Payload Invalido -> 400 Problem Details)..." -ForegroundColor Yellow
    $InvalidJson = '{"name": "T", "email": "email_invalido", "documentNumber": "123", "creditLimit": -50.0}'
    $Content2 = New-Object System.Net.Http.StringContent($InvalidJson, [System.Text.Encoding]::UTF8, "application/json")
    $Resp2 = $HttpClient.PostAsync("$BaseUrl/api/v1/clientes", $Content2).Result
    $Body2 = $Resp2.Content.ReadAsStringAsync().Result
    
    if ($Resp2.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest -and $Body2 -match "Name" -and $Body2 -match "Email") {
        Write-Host "  [SUCESSO] HTTP 400 Bad Request (Fail-Fast ativo)" -ForegroundColor Green
        Write-Host "            Body: $Body2" -ForegroundColor Gray
    } else {
        Write-Host "  [FALHA] Esperado 400 Bad Request com erros detalhados. Recebido: $($Resp2.StatusCode)" -ForegroundColor Red
        Write-Host "          Body: $Body2" -ForegroundColor Red
        $Success = $false
    }

    # 3. Teste: GET /api/v1/clientes/{id} (200 OK)
    Write-Host "`n[TEST 3] GET /api/v1/clientes/42 (Consulta por ID -> 200 OK)..." -ForegroundColor Yellow
    $Resp3 = $HttpClient.GetAsync("$BaseUrl/api/v1/clientes/42").Result
    $Body3 = $Resp3.Content.ReadAsStringAsync().Result
    
    if ($Resp3.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body3 -match "Empresa Alfa") {
        Write-Host "  [SUCESSO] HTTP 200 OK | Body: $Body3" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 200 OK. Recebido: $($Resp3.StatusCode)" -ForegroundColor Red
        $Success = $false
    }

    # 4. Teste: GET /api/v1/clientes/999 (404 Not Found)
    Write-Host "`n[TEST 4] GET /api/v1/clientes/999 (Registro Inexistente -> 404 Not Found)..." -ForegroundColor Yellow
    $Resp4 = $HttpClient.GetAsync("$BaseUrl/api/v1/clientes/999").Result
    
    if ($Resp4.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {
        Write-Host "  [SUCESSO] HTTP 404 Not Found retornado corretamente." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 404 Not Found. Recebido: $($Resp4.StatusCode)" -ForegroundColor Red
        $Success = $false
    }

    # 5. Teste: GET /api/v1/clientes (Multi-Fonte com Header X-Tenant-ID -> 200 OK)
    Write-Host "`n[TEST 5] GET /api/v1/clientes (Multi-Fonte com X-Tenant-ID -> 200 OK)..." -ForegroundColor Yellow
    $Req5 = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, "$BaseUrl/api/v1/clientes?status=ATIVO&limite=10")
    $Req5.Headers.Add("X-Tenant-ID", "tenant_filial_sp")
    $Resp5 = $HttpClient.SendAsync($Req5).Result
    $Body5 = $Resp5.Content.ReadAsStringAsync().Result
    
    if ($Resp5.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body5 -match "tenant_filial_sp") {
        Write-Host "  [SUCESSO] HTTP 200 OK | Body: $Body5" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 200 OK com dados de tenant. Recebido: $($Resp5.StatusCode)" -ForegroundColor Red
        $Success = $false
    }

    # 6. Teste: DELETE /api/v1/clientes/42 (204 No Content)
    Write-Host "`n[TEST 6] DELETE /api/v1/clientes/42 (Inativacao -> 204 No Content)..." -ForegroundColor Yellow
    $Resp6 = $HttpClient.DeleteAsync("$BaseUrl/api/v1/clientes/42").Result
    
    if ($Resp6.StatusCode -eq [System.Net.HttpStatusCode]::NoContent) {
        Write-Host "  [SUCESSO] HTTP 204 No Content retornado com sucesso." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado 204 No Content. Recebido: $($Resp6.StatusCode)" -ForegroundColor Red
        $Success = $false
    }
}
finally {
    $HttpClient.Dispose()
    if ($Process -and (-not $KeepRunning)) {
        Write-Host "`n[TEARDOWN] Finalizando processo do servidor (PID: $($Process.Id))..." -ForegroundColor Gray
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
    }
}

if ($Success) {
    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host "   TODOS OS TESTES DO LABORATORIO 1 PASSARAM COM EXITO! " -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n========================================================" -ForegroundColor Red
    Write-Host "   FALHA NA SUITE DE TESTES DO LABORATORIO 1!           " -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    exit 1
}
