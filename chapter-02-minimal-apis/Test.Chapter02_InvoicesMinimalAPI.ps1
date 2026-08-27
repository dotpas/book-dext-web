# =============================================================================
# Test.Chapter02_InvoicesMinimalAPI.ps1 - Minimal APIs & Results Validation
# Project: Chapter02_InvoicesMinimalAPI.dpr (Chapter 02)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter02_InvoicesMinimalAPI.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter02_InvoicesMinimalAPI" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter02_InvoicesMinimalAPI.dpr antes de rodar os testes." -ForegroundColor Yellow
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

$Client = New-Object System.Net.Http.HttpClient
$Client.Timeout = [TimeSpan]::FromSeconds(5)

$TestsPassed = 0
$TestsFailed = 0

function Assert-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [string]$Payload,
        [int]$ExpectedStatus,
        [string]$ExpectedSubstring
    )

    try {
        if ($Method -eq "GET") {
            $Response = $Client.GetAsync($Url).GetAwaiter().GetResult()
        } elseif ($Method -eq "POST") {
            $Content = New-Object System.Net.Http.StringContent($Payload, [System.Text.Encoding]::UTF8, "application/json")
            $Response = $Client.PostAsync($Url, $Content).GetAwaiter().GetResult()
        } elseif ($Method -eq "DELETE") {
            $Response = $Client.DeleteAsync($Url).GetAwaiter().GetResult()
        }

        $StatusCode = [int]$Response.StatusCode
        $Body = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

        $StatusMatch = ($StatusCode -eq $ExpectedStatus)
        $BodyMatch = ($null -eq $ExpectedSubstring) -or ($Body.Contains($ExpectedSubstring))

        if ($StatusMatch -and $BodyMatch) {
            Write-Host "  [PASS] $Name -> Status: $StatusCode" -ForegroundColor Green
            $global:TestsPassed++
        } else {
            Write-Host "  [FAIL] $Name -> Esperado: $ExpectedStatus | Obtido: $StatusCode" -ForegroundColor Red
            if (-not $BodyMatch) {
                Write-Host "         Substring esperada: '$ExpectedSubstring'" -ForegroundColor DarkRed
                Write-Host "         Corpo recebido: $Body" -ForegroundColor DarkRed
            }
            $global:TestsFailed++
        }
    } catch {
        Write-Host "  [FAIL] $Name -> Erro de Conexao: $($_.Exception.Message)" -ForegroundColor Red
        $global:TestsFailed++
    }
}

try {
    Write-Host "`nExecutando validacao de endpoints..." -ForegroundColor White

    # 1. Rota Fixa Resumo
    Assert-Endpoint -Name "GET /api/v1/faturas/resumo (Status 200)" `
                    -Method "GET" `
                    -Url "$BaseUrl/api/v1/faturas/resumo" `
                    -ExpectedStatus 200 `
                    -ExpectedSubstring "totalFaturas"

    # 2. Rota Parametrizada ID Existente
    Assert-Endpoint -Name "GET /api/v1/faturas/105 (Status 200)" `
                    -Method "GET" `
                    -Url "$BaseUrl/api/v1/faturas/105" `
                    -ExpectedStatus 200 `
                    -ExpectedSubstring "clienteId"

    # 3. Rota Parametrizada ID Inexistente (404)
    Assert-Endpoint -Name "GET /api/v1/faturas/999 (Status 404)" `
                    -Method "GET" `
                    -Url "$BaseUrl/api/v1/faturas/999" `
                    -ExpectedStatus 404 `
                    -ExpectedSubstring "nao encontrada"

    # 4. Rota Query String com Filtros
    Assert-Endpoint -Name "GET /api/v1/faturas?status=Pendente&limite=10 (Status 200)" `
                    -Method "GET" `
                    -Url "$BaseUrl/api/v1/faturas?status=Pendente&limite=10" `
                    -ExpectedStatus 200 `
                    -ExpectedSubstring "Pendente"

    # 5. Rota Criação POST com DTO
    $PostPayload = '{"clienteId":42,"valor":750.50,"vencimento":"2026-08-30"}'
    Assert-Endpoint -Name "POST /api/v1/faturas (Status 201 Created)" `
                    -Method "POST" `
                    -Url "$BaseUrl/api/v1/faturas" `
                    -Payload $PostPayload `
                    -ExpectedStatus 201 `
                    -ExpectedSubstring "EMITIDA"

    # 6. Rota Exclusão DELETE
    Assert-Endpoint -Name "DELETE /api/v1/faturas/105 (Status 204 NoContent)" `
                    -Method "DELETE" `
                    -Url "$BaseUrl/api/v1/faturas/105" `
                    -ExpectedStatus 204 `
                    -ExpectedSubstring ""

    # 7. Rota Semântica Tipada com IResult e Results
    Assert-Endpoint -Name "GET /api/v1/faturas/semantica/105 (Status 200 via IResult)" `
                    -Method "GET" `
                    -Url "$BaseUrl/api/v1/faturas/semantica/105" `
                    -ExpectedStatus 200 `
                    -ExpectedSubstring "Funcional"

    Assert-Endpoint -Name "GET /api/v1/faturas/semantica/999 (Status 404 via Results.NotFound)" `
                    -Method "GET" `
                    -Url "$BaseUrl/api/v1/faturas/semantica/999" `
                    -ExpectedStatus 404 `
                    -ExpectedSubstring "nao encontrada"

    Write-Host "`n--------------------------------------------------------------------"
    Write-Host "Resultado dos Testes: $TestsPassed Aprovados | $TestsFailed Falhas" -ForegroundColor $(if ($TestsFailed -eq 0) { "Green" } else { "Red" })
    Write-Host "--------------------------------------------------------------------"

} finally {
    $Client.Dispose()
    if ($Process -and -not $Process.HasExited -and $AutoClose -and -not $WasAlreadyRunning) {
        Write-Host "[SHUTDOWN] Encerrando servidor temporario (PID: $($Process.Id))..." -ForegroundColor Gray
        $Process.Kill()
    } elseif ($Process -and -not $Process.HasExited) {
        Write-Host "[KEEP-ALIVE] Servidor mantido em execucao em $BaseUrl (PID: $($Process.Id))." -ForegroundColor Cyan
    }
}

if ($TestsFailed -gt 0) { exit 1 }
