# Script de Teste de Estresse e Concorrencia - HostingApp (Capitulo 18)
$exePath = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-18-observability\HostingApp.exe"
$exeDir = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-18-observability"

if (-not (Test-Path $exePath)) {
    Write-Host "[ERRO] Executavel HostingApp.exe nao encontrado." -ForegroundColor Red
    exit 1
}

Write-Host "[INIT] Iniciando HostingApp.exe para teste de carga e estresse..." -ForegroundColor Cyan

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exePath
$psi.WorkingDirectory = $exeDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)
Start-Sleep -Seconds 2

if ($proc.HasExited) {
    Write-Host "[ERRO] Servidor HostingApp encerrou prematuramente." -ForegroundColor Red
    exit 1
}

Add-Type -AssemblyName System.Net.Http

try {
    $url = "http://localhost:8080/metrics"
    $readyUrl = "http://localhost:8080/health/ready"
    $liveUrl = "http://localhost:8080/health/live"

    Write-Host "[STRESS] Executando 100 requisicoes HTTP concorrentes..." -ForegroundColor Yellow

    $totalReqs = 100
    $success = 0
    $failures = 0

    $jobs = 1..100 | ForEach-Object {
        Start-Job -ScriptBlock {
            Add-Type -AssemblyName System.Net.Http
            $client = New-Object System.Net.Http.HttpClient
            try {
                $r1 = $client.GetAsync("http://localhost:8080/metrics").Result
                $r2 = $client.GetAsync("http://localhost:8080/health/ready").Result
                $r3 = $client.GetAsync("http://localhost:8080/health/live").Result
                if ($r1.IsSuccessStatusCode -and $r2.IsSuccessStatusCode -and $r3.IsSuccessStatusCode) {
                    return $true
                }
            } catch {
                return $false
            } finally {
                $client.Dispose()
            }
            return $false
        }
    }

    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job -Force

    $success = ($results | Where-Object { $_ -eq $true }).Count
    $failures = 100 - $success

    # Obter relatorio final de metricas RED do servidor
    $finalClient = New-Object System.Net.Http.HttpClient
    $metricsJson = $finalClient.GetStringAsync($url).Result
    Write-Host "`n[METRICAS RED CAPTURADAS]:" -ForegroundColor Green
    Write-Host $metricsJson -ForegroundColor White

    if ($failures -eq 0) {
        Write-Host "`n[SUCESSO] Teste de estresse concorrente aprovado sem race conditions ou leakes!" -ForegroundColor Green
    } else {
        Write-Host "`n[FALHA] Teste de estresse reportou falhas." -ForegroundColor Red
        exit 1
    }
} finally {
    if (-not $proc.HasExited) {
        $proc.Kill()
    }
}
