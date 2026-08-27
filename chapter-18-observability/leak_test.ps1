# Script de Teste de Vazamento de Memoria - HostingApp (Capitulo 18)
$exePath = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-18-observability\HostingApp.exe"
$exeDir = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-18-observability"

if (-not (Test-Path $exePath)) {
    Write-Host "[ERRO] Executavel HostingApp.exe nao encontrado." -ForegroundColor Red
    exit 1
}

Write-Host "[INIT] Iniciando HostingApp.exe para teste de memoria multi-ciclo..." -ForegroundColor Cyan

Get-Process -Name "HostingApp" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exePath
$psi.WorkingDirectory = $exeDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)
Start-Sleep -Seconds 3

if ($proc.HasExited) {
    Write-Host "[ERRO] Servidor HostingApp encerrou prematuramente." -ForegroundColor Red
    exit 1
}

Add-Type -AssemblyName System.Net.Http

try {
    $proc.Refresh()
    $baselineWorkingSetMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
    $baselinePrivateMB = [math]::Round($proc.PrivateMemorySize64 / 1MB, 2)

    Write-Host "[STABILITY TEST] Baseline do Processo Delphi (PID: $($proc.Id)) - WorkingSet: $baselineWorkingSetMB MB | PrivateBytes: $baselinePrivateMB MB" -ForegroundColor Yellow

    $totalCycles = 3
    $reqsPerCycle = 500
    $totalRequestsAllCycles = $totalCycles * $reqsPerCycle
    $cycleResults = @()

    1..$totalCycles | ForEach-Object {
        $cycleNum = $_
        Write-Host "`n[CICLO $cycleNum / $totalCycles] Executando rajada de $reqsPerCycle requisicoes HTTP..." -ForegroundColor Yellow

        $totalJobs = 10
        $reqsPerJob = 50

        $jobs = 1..$totalJobs | ForEach-Object {
            Start-Job -ScriptBlock {
                param($reqs)
                Add-Type -AssemblyName System.Net.Http
                $client = New-Object System.Net.Http.HttpClient
                $successCount = 0
                try {
                    1..$reqs | ForEach-Object {
                        $retry = 0
                        $ok = $false
                        while (-not $ok -and $retry -lt 3) {
                            try {
                                $res = $client.GetAsync("http://localhost:8080/metrics").Result
                                if ($res.IsSuccessStatusCode) {
                                    $successCount++
                                    $ok = $true
                                }
                            } catch {
                                $retry++
                                Start-Sleep -Milliseconds 50
                            }
                        }
                    }
                    return $successCount
                } catch {
                    return 0
                } finally {
                    $client.Dispose()
                }
            } -ArgumentList $reqsPerJob
        }

        $results = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job -Force

        $successfulInCycle = 0
        foreach ($r in $results) { $successfulInCycle += [int]$r }

        Start-Sleep -Seconds 2
        $proc.Refresh()

        $curWS = [math]::Round($proc.WorkingSet64 / 1MB, 2)
        $curPriv = [math]::Round($proc.PrivateMemorySize64 / 1MB, 2)
        $deltaPriv = [math]::Round($curPriv - $baselinePrivateMB, 2)

        Write-Host "  [+] Ciclo $cycleNum Concluido: $successfulInCycle / $reqsPerCycle Requisicoes OK | RAM PrivateBytes: $curPriv MB (Delta do Baseline: $deltaPriv MB)" -ForegroundColor $(if ($successfulInCycle -eq $reqsPerCycle) { "Green" } else { "Red" })

        if ($successfulInCycle -ne $reqsPerCycle) {
            Write-Host "[FALHA CRITICA] Requisicoes falharam no Ciclo $cycleNum!" -ForegroundColor Red
            exit 1
        }

        $cycleResults += [PSCustomObject]@{
            Ciclo = $cycleNum
            Sucessos = $successfulInCycle
            PrivateBytesMB = $curPriv
            DeltaMB = $deltaPriv
        }
    }

    $proc.Refresh()
    $finalWorkingSetMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
    $finalPrivateMB = [math]::Round($proc.PrivateMemorySize64 / 1MB, 2)
    $totalDeltaPrivateMB = [math]::Round($finalPrivateMB - $baselinePrivateMB, 2)

    Write-Host "`n====================================================" -ForegroundColor Cyan
    Write-Host "RELATORIO DE ESTABILIDADE DE MEMORIA MULTI-CICLO (1.500 REQUISICOES TOTAIS):" -ForegroundColor Cyan
    Write-Host "  RAM Inicial (Baseline):    $baselinePrivateMB MB"
    Write-Host "  RAM Final (Apos 3 Ciclos): $finalPrivateMB MB"
    Write-Host "  Variaçao Total (Delta):    $totalDeltaPrivateMB MB"
    Write-Host "====================================================" -ForegroundColor Cyan

    $reportContent = @"
====================================================
DEXT FRAMEWORK - MULTI-CYCLE MEMORY STABILITY REPORT
====================================================
Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Executavel: HostingApp.exe (PID: $($proc.Id))
Total Ciclos: $totalCycles
Total Requisicoes: $totalRequestsAllCycles / $totalRequestsAllCycles (100% Sucesso)
Baseline PrivateBytes: $baselinePrivateMB MB
Final PrivateBytes:    $finalPrivateMB MB
Delta Total Private:   $totalDeltaPrivateMB MB
Status Final:          $(if ($totalDeltaPrivateMB -le 5.0) { 'PASS - Estabilidade de Memória Verificada sem Tendencia Acumulativa de Leak' } else { 'FAIL - Crescimento de Memoria Excessivo' })
====================================================
"@

    $reportPath = Join-Path $exeDir "leak_test_report.txt"
    Set-Content -Path $reportPath -Value $reportContent
    Write-Host "`n[REPORT] Relatorio salvo em: $reportPath" -ForegroundColor Green

    # Dispara encerramento gracioso via /admin/shutdown para acionar o ReportMemoryLeaksOnShutdown do Delphi
    Write-Host "`n[SHUTDOWN] Enviando POST /admin/shutdown para disparar finalização limpa e ReportMemoryLeaksOnShutdown..." -ForegroundColor Yellow
    $shutdownClient = New-Object System.Net.Http.HttpClient
    try {
        $reqShutdown = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, "http://localhost:8080/admin/shutdown")
        $reqShutdown.Headers.Add("X-Infrastructure-Test-Key", "infra_test_secret_key")
        $resShutdown = $shutdownClient.SendAsync($reqShutdown).Result
        Write-Host "  [+] Resposta do Shutdown: $($resShutdown.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Aviso no shutdown: $($_.Exception.Message)" -ForegroundColor Yellow
    } finally {
        $shutdownClient.Dispose()
    }

    Write-Host "[SHUTDOWN] Aguardando término limpo do processo Delphi (PID: $($proc.Id))..." -ForegroundColor Yellow
    $stoppedCleanly = $proc.WaitForExit(5000)

    if ($stoppedCleanly -and $proc.ExitCode -eq 0) {
        Write-Host "  [+] Processo Delphi encerrado de forma coordenada com ExitCode 0." -ForegroundColor Green
    } else {
        Write-Host "  [-] Processo nao encerrou corretamente em 5s." -ForegroundColor Red
        if (-not $proc.HasExited) { $proc.Kill() }
        exit 1
    }

    if ($totalDeltaPrivateMB -le 5.0) {
        Write-Host "`n[SUCESSO] Teste de estabilidade de memoria multi-ciclo e finalizacao limpa APROVADOS!" -ForegroundColor Green
    } else {
        Write-Host "`n[FALHA] Crescimento acumulativo de memoria ($totalDeltaPrivateMB MB) excede o limite." -ForegroundColor Red
        exit 1
    }
} finally {
    if (-not $proc.HasExited) {
        $proc.Kill()
    }
}
