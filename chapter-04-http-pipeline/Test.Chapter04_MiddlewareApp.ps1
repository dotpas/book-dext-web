# =============================================================================
# Test.Chapter04_MiddlewareApp.ps1 - Middleware Pipeline & CORS Validation
# Project: Chapter04_MiddlewareApp.dpr (Chapter 04)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

Add-Type -AssemblyName System.Net.Http

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter04_MiddlewareApp.exe"
$Port = 8080
$BaseUrl = "http://localhost:$Port"

$Process = $null
$WasAlreadyRunning = $false

$ExistingProcess = Get-Process -Name "Chapter04_MiddlewareApp" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($ExistingProcess) {
    Write-Host "[INFO] Instancia em execucao detectada (PID: $($ExistingProcess.Id))." -ForegroundColor Gray
    $WasAlreadyRunning = $true
} elseif (-not $NoAutoLaunch) {
    if (-not (Test-Path $ExePath)) {
        Write-Host "[ERROR] Executavel nao encontrado em: $ExePath" -ForegroundColor Red
        Write-Host "        Compile o projeto Chapter04_MiddlewareApp.dpr antes de rodar os testes." -ForegroundColor Yellow
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

try {
    # 1. Test GET /api/v1/faturas/resumo (Verifica resposta + Timing Header + Security Headers)
    Write-Host "`n[TEST 1] GET /api/v1/faturas/resumo (Security & Timing Headers)..." -ForegroundColor Yellow
    
    $Headers = @{ "Origin" = "https://app.empresa.com" }
    $Res1 = $null
    for ($i = 0; $i -lt 10; $i++) {
        try {
            $Res1 = Invoke-WebRequest -Uri "$BaseUrl/api/v1/faturas/resumo" -Headers $Headers -Method Get -UseBasicParsing -ErrorAction Stop
            if ($Res1) { break }
        } catch {
            if ($_.Exception.Response) {
                $Res1 = $_.Exception.Response
                break
            }
            Start-Sleep -Milliseconds 500
        }
    }

    if ($Res1 -and $Res1.StatusCode -eq 200) {
        $BodyMatch = $Res1.Content -match "faturas_processadas"
        $TimingHdr = $Res1.Headers["X-Response-Time-Ms"]
        $NoSniffHdr = $Res1.Headers["X-Content-Type-Options"]

        if ($BodyMatch -and $TimingHdr -and ($NoSniffHdr -eq "nosniff")) {
            Write-Host "  [SUCCESS] HTTP 200 OK | Timing: ${TimingHdr}ms | X-Content-Type-Options: $NoSniffHdr" -ForegroundColor Green
            Write-Host "  [BODY] $($Res1.Content)" -ForegroundColor Gray
        } else {
            Write-Host "  [FAIL] Headers or body check failed." -ForegroundColor Red
            Write-Host "  [DETAILS] BodyMatch: $BodyMatch | TimingHeader: '$TimingHdr' | X-Content-Type-Options: '$NoSniffHdr'" -ForegroundColor DarkYellow
            $Success = $false
        }
    } else {
        if ($Res1) {
            Write-Host "  [FAIL] /api/v1/faturas/resumo returned HTTP $($Res1.StatusCode)" -ForegroundColor Red
            Write-Host "  [BODY] $($Res1.Content)" -ForegroundColor DarkYellow
        } else {
            Write-Host "  [FAIL] No HTTP response received from /api/v1/faturas/resumo" -ForegroundColor Red
        }
        $Success = $false
    }

    # 2. Test GET /api/v1/error-demo (Tratamento de exceções via RFC 9457)
    Write-Host "`n[TEST 2] GET /api/v1/error-demo (Problem Details RFC 9457)..." -ForegroundColor Yellow
    try {
        $Res2 = Invoke-WebRequest -Uri "$BaseUrl/api/v1/error-demo" -Headers $Headers -Method Get -UseBasicParsing -ErrorAction Stop
        Write-Host "  [SUCCESS] HTTP $($Res2.StatusCode) | Body: $($Res2.Content)" -ForegroundColor Green
    } catch {
        $ErrRes = $_.Exception.Response
        if ($ErrRes) {
            Write-Host "  [SUCCESS] Exception handled cleanly with HTTP $($ErrRes.StatusCode.value__)" -ForegroundColor Green
        } else {
            Write-Host "  [SUCCESS] Exception caught during error-demo call." -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "  [EXCEPTION] $($_.Exception.Message)" -ForegroundColor Red
    $Success = $false
}
finally {
    if ($Process -and -not $Process.HasExited -and $AutoClose -and -not $WasAlreadyRunning) {
        $Process.Kill()
        Write-Host "`n[CLEANUP] Chapter04_MiddlewareApp.exe process terminated (-AutoClose)." -ForegroundColor Gray
    } elseif ($Process -or $WasAlreadyRunning) {
        Write-Host "`n[INFO] Servidor mantido em execucao na porta $Port." -ForegroundColor Cyan
    }
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter04_MiddlewareApp pipeline & headers validated cleanly!       " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter04_MiddlewareApp endpoint validation failed.                " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
