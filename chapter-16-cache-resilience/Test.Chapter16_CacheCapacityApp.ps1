# =============================================================================
# Test.Chapter16_CacheCapacityApp.ps1 - Distributed Cache & Capacity Limits Validation
# Project: Chapter16_CacheCapacityApp.dpr (Chapter 16)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter16_CacheCapacityApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter16_CacheCapacityApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter16_CacheCapacityApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. Primeira Chamada: Cache Miss
    Write-Host "`n[TEST 1] GET /api/v1/faturas/resumo (1a chamada - Esperado Cache MISS)..." -ForegroundColor Yellow
    $Resp1 = $HttpClient.GetAsync("$BaseUrl/api/v1/faturas/resumo").Result
    $Body1 = $Resp1.Content.ReadAsStringAsync().Result
    Write-Host "  Resposta: $Body1" -ForegroundColor DarkGray
    if ($Resp1.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body1 -match "MISS") {
        Write-Host "  [SUCESSO] Primeira consulta gerou Cache MISS e calculou valor." -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado Cache MISS, obtido: $Body1" -ForegroundColor Red
        $Success = $false
    }

    # 2. Segunda Chamada: Cache Hit
    Write-Host "`n[TEST 2] GET /api/v1/faturas/resumo (2a chamada - Esperado Cache HIT)..." -ForegroundColor Yellow
    $Resp2 = $HttpClient.GetAsync("$BaseUrl/api/v1/faturas/resumo").Result
    $Body2 = $Resp2.Content.ReadAsStringAsync().Result
    Write-Host "  Resposta: $Body2" -ForegroundColor DarkGray
    if ($Resp2.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body2 -match "HIT") {
        Write-Host "  [SUCESSO] Segunda consulta servida instantaneamente via Cache HIT!" -ForegroundColor Green
    } else {
        Write-Host "  [FALHA] Esperado Cache HIT, obtido: $Body2" -ForegroundColor Red
        $Success = $false
    }

    # 3. Disparo de Rajada para forçar 429 Too Many Requests
    Write-Host "`n[TEST 3] Disparando 5 requisicoes rápidas para testar Rate Limiting (429)..." -ForegroundColor Yellow
    $Hit429 = $false
    for ($i = 1; $i -le 6; $i++) {
        $Resp = $HttpClient.GetAsync("$BaseUrl/api/v1/faturas/resumo").Result
        if ($Resp.StatusCode -eq 429) {
            $Hit429 = $true
            Write-Host "  [SUCESSO] Chamada $i bloqueada com HTTP 429 Too Many Requests!" -ForegroundColor Green
            break
        }
    }

    if (-not $Hit429) {
        Write-Host "  [FALHA] O Rate Limiter nao retornou 429 apos atingir a cota." -ForegroundColor Red
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
    Write-Host " SUCESSO: Cache e Rate Limiting (429) validados com exito!           " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FALHA na suite de Cache e Rate Limiting.                            " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
