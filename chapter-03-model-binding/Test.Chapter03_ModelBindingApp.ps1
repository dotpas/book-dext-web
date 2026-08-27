# =============================================================================
# Test.Chapter03_ModelBindingApp.ps1 - Model Binding & File Upload Validation
# Project: Chapter03_ModelBindingApp.dpr (Chapter 03)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter03_ModelBindingApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter03_ModelBindingApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter03_ModelBindingApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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
    # 1. Test GET /api/v1/clientes/{clienteId}/faturas (Multi-Source Binding)
    Write-Host "`n[TEST 1] GET /api/v1/clientes/42/faturas (Multi-Fonte: Header+Route+Query)..." -ForegroundColor Yellow
    $Req1 = New-Object System.Net.Http.HttpRequestMessage(
        [System.Net.Http.HttpMethod]::Get,
        "$BaseUrl/api/v1/clientes/42/faturas?status=PAGA&limite=10"
    )
    $Req1.Headers.Add("X-Tenant-ID", "tenant_empresa_alfa")
    $Res1 = $HttpClient.SendAsync($Req1).Result
    $Body1 = $Res1.Content.ReadAsStringAsync().Result

    if ($Res1.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body1 -match "tenant_empresa_alfa" -and $Body1 -match "42") {
        Write-Host "  [SUCCESS] HTTP 200 OK | Body: $Body1" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($Res1.StatusCode) | Body: $Body1" -ForegroundColor Red
        $Success = $false
    }

    # 2. Test GET with missing required header (Validation Fail-Fast)
    Write-Host "`n[TEST 2] GET /api/v1/clientes/42/faturas without X-Tenant-ID header..." -ForegroundColor Yellow
    $Res2 = $HttpClient.GetAsync("$BaseUrl/api/v1/clientes/42/faturas?status=PAGA").Result
    $Body2 = $Res2.Content.ReadAsStringAsync().Result

    if ($Res2.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {
        Write-Host "  [SUCCESS] HTTP 400 Bad Request retornado corretamente." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($Res2.StatusCode) inesperado | Body: $Body2" -ForegroundColor Red
        $Success = $false
    }

    # 3. Test POST Multipart /api/v1/faturas/105/comprovante
    Write-Host "`n[TEST 3] POST /api/v1/faturas/105/comprovante (Multipart Upload Real)..." -ForegroundColor Yellow
    $Form = New-Object System.Net.Http.MultipartFormDataContent
    $FileBytes = [System.Text.Encoding]::UTF8.GetBytes("%PDF-1.4 Mock Receipt Content for Chapter 3")
    $ByteArrayContent = New-Object System.Net.Http.ByteArrayContent($FileBytes, 0, $FileBytes.Length)
    $ByteArrayContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/pdf")
    $Form.Add($ByteArrayContent, "arquivo", "recibo_fatura_105.pdf")

    $Res3 = $HttpClient.PostAsync("$BaseUrl/api/v1/faturas/105/comprovante", $Form).Result
    $Body3 = $Res3.Content.ReadAsStringAsync().Result

    $UploadedFilePath = Join-Path (Join-Path $ScriptDir "uploads") "fatura_105_recibo_fatura_105.pdf"
    $FileActuallySaved = Test-Path $UploadedFilePath

    if ($Res3.StatusCode -eq [System.Net.HttpStatusCode]::Created -and $FileActuallySaved) {
        Write-Host "  [SUCCESS] HTTP $($Res3.StatusCode) | Arquivo gravado fisicamente em disco!" -ForegroundColor Green
        Write-Host "  [VERIFY] Arquivo salvo em: $UploadedFilePath" -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] HTTP $($Res3.StatusCode) | Arquivo no disco: $FileActuallySaved | Body: $Body3" -ForegroundColor Red
        $Success = $false
    }

    # 4. Test QUERY /api/v1/faturas/consultar-avancado (RFC 10008)
    Write-Host "`n[TEST 4] QUERY /api/v1/faturas/consultar-avancado (RFC 10008 QUERY method)..." -ForegroundColor Yellow
    $ReqQuery = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::new("QUERY"), "$BaseUrl/api/v1/faturas/consultar-avancado")
    $JsonPayload = '{"CentrosCusto":["TI","Vendas"],"StatusList":["PAGA","EM_ABERTO"],"ValorMinimo":100.0,"ValorMaximo":5000.0}'
    $ReqQuery.Content = New-Object System.Net.Http.StringContent($JsonPayload, [System.Text.Encoding]::UTF8, "application/json")
    
    $Res4 = $HttpClient.SendAsync($ReqQuery).Result
    $Body4 = $Res4.Content.ReadAsStringAsync().Result

    if ($Res4.StatusCode -eq [System.Net.HttpStatusCode]::OK -and $Body4 -match "Busca processada") {
        Write-Host "  [SUCCESS] HTTP 200 OK | Body: $Body4" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] HTTP $($Res4.StatusCode) | Body: $Body4" -ForegroundColor Red
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
        Write-Host "`n[CLEANUP] Chapter03_ModelBindingApp.exe process terminated (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter03_ModelBindingApp endpoints validated cleanly!             " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter03_ModelBindingApp endpoint validation failed.              " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
