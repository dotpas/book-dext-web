# Script de Verificação Independente e Reprodutível de Probes, Políticas de Segurança e Autenticação
# Localização: Docs/dext-developer-bookshelf/book/examples/verify_all_security_probes.ps1

Add-Type -AssemblyName System.Net.Http

function Test-HostingProbes {
    Write-Host "`n[TEST 1] Validando Readiness Probe Real SQLite e Fail-State em HostingApp..." -ForegroundColor Cyan
    $exePath = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-18-observability\HostingApp.exe"
    $exeDir = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-18-observability"

    Get-Process -Name "HostingApp" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    $proc = [System.Diagnostics.Process]::Start((New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = $exePath; WorkingDirectory = $exeDir; UseShellExecute = $false; CreateNoWindow = $true
    }))
    Start-Sleep -Seconds 3

    $client = New-Object System.Net.Http.HttpClient
    try {
        # 1a. Probe 200 Healthy com Conexao Real SQLite
        $res1 = $client.GetAsync("http://localhost:8080/health/ready").Result
        $body1 = $res1.Content.ReadAsStringAsync().Result
        Write-Host "  [+] Readiness Healthy HTTP Code: $($res1.StatusCode) (Esperado: OK)" -ForegroundColor $(if ($res1.StatusCode -eq [System.Net.HttpStatusCode]::OK) { "Green" } else { "Red" })
        if ($res1.StatusCode -ne [System.Net.HttpStatusCode]::OK) { Write-Host "      Body: $body1" -ForegroundColor Red }
        if ($res1.StatusCode -ne [System.Net.HttpStatusCode]::OK) { exit 1 }

        # 1b. Tentativa de alteracao sem header administrativo (Rejeitada)
        $resNoAuth = $client.PostAsync("http://localhost:8080/health/toggle-db?online=false", $null).Result
        Write-Host "  [+] Toggle DB Sem Header Secret HTTP Code: $($resNoAuth.StatusCode) (Esperado: Unauthorized)" -ForegroundColor $(if ($resNoAuth.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) { "Green" } else { "Red" })
        if ($resNoAuth.StatusCode -ne [System.Net.HttpStatusCode]::Unauthorized) { exit 1 }

        # 1c. Alternar Conectividade com Header Secret Autorizado
        $reqToggle = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, "http://localhost:8080/health/toggle-db?online=false")
        $reqToggle.Headers.Add("X-Infrastructure-Test-Key", "infra_test_secret_key")
        $resToggle = $client.SendAsync($reqToggle).Result
        Write-Host "  [+] Toggle DB Com Header Secret HTTP Code: $($resToggle.StatusCode) (Esperado: OK)" -ForegroundColor $(if ($resToggle.StatusCode -eq [System.Net.HttpStatusCode]::OK) { "Green" } else { "Red" })
        if ($resToggle.StatusCode -ne [System.Net.HttpStatusCode]::OK) { exit 1 }

        # 1d. Probe 503 Service Unavailable no Fail-State Atômico
        $res2 = $client.GetAsync("http://localhost:8080/health/ready").Result
        Write-Host "  [+] Readiness Unhealthy HTTP Code: $($res2.StatusCode) (Esperado: ServiceUnavailable)" -ForegroundColor $(if ($res2.StatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable) { "Green" } else { "Red" })
        if ($res2.StatusCode -ne [System.Net.HttpStatusCode]::ServiceUnavailable) { exit 1 }
    } finally {
        $client.Dispose()
        if (-not $proc.HasExited) { $proc.Kill() }
    }
}

function Test-DataApiPolicy {
    Write-Host "`n[TEST 2] Validando Allowlist de Verbos, Campos e Faixa de Paginação na DataAPI..." -ForegroundColor Cyan
    $exePath = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-13-database-as-api\DataApiApp.exe"
    $exeDir = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-13-database-as-api"

    Get-Process -Name "DataApiApp" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    $proc = [System.Diagnostics.Process]::Start((New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = $exePath; WorkingDirectory = $exeDir; UseShellExecute = $false; CreateNoWindow = $true
    }))
    Start-Sleep -Seconds 3

    $client = New-Object System.Net.Http.HttpClient
    try {
        # 2a. GET Autorizado pela Allowlist
        $resGet = $client.GetAsync("http://localhost:8080/api/v1/customers").Result
        $bodyGet = $resGet.Content.ReadAsStringAsync().Result
        Write-Host "  [+] GET /api/v1/customers HTTP Code: $($resGet.StatusCode) (Esperado: OK)" -ForegroundColor $(if ($resGet.StatusCode -eq [System.Net.HttpStatusCode]::OK) { "Green" } else { "Red" })
        if ($resGet.StatusCode -ne [System.Net.HttpStatusCode]::OK) { Write-Host "      Body: $bodyGet" -ForegroundColor Red }
        if ($resGet.StatusCode -ne [System.Net.HttpStatusCode]::OK) { exit 1 }

        # 2b. DELETE Bloqueado pela Allowlist (Verbo Proibido)
        $reqDelete = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Delete, "http://localhost:8080/api/v1/customers/1")
        $resDelete = $client.SendAsync($reqDelete).Result
        Write-Host "  [+] DELETE /api/v1/customers/1 HTTP Code: $($resDelete.StatusCode) (Esperado: Forbidden)" -ForegroundColor $(if ($resDelete.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden) { "Green" } else { "Red" })
        if ($resDelete.StatusCode -ne [System.Net.HttpStatusCode]::Forbidden) { exit 1 }

        # 2c. PUT Bloqueado pela Allowlist (Verbo Proibido)
        $reqPut = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Put, "http://localhost:8080/api/v1/customers/1")
        $resPut = $client.SendAsync($reqPut).Result
        Write-Host "  [+] PUT /api/v1/customers/1 HTTP Code: $($resPut.StatusCode) (Esperado: Forbidden)" -ForegroundColor $(if ($resPut.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden) { "Green" } else { "Red" })
        if ($resPut.StatusCode -ne [System.Net.HttpStatusCode]::Forbidden) { exit 1 }

        # 2d. Limit Excedido (limit > 100)
        $resLimitMax = $client.GetAsync("http://localhost:8080/api/v1/customers?limit=500").Result
        Write-Host "  [+] GET /api/v1/customers?limit=500 HTTP Code: $($resLimitMax.StatusCode) (Esperado: BadRequest)" -ForegroundColor $(if ($resLimitMax.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) { "Green" } else { "Red" })
        if ($resLimitMax.StatusCode -ne [System.Net.HttpStatusCode]::BadRequest) { exit 1 }

        # 2e. Limit Inválido/Negativo (limit=-10)
        $resLimitNeg = $client.GetAsync("http://localhost:8080/api/v1/customers?limit=-10").Result
        Write-Host "  [+] GET /api/v1/customers?limit=-10 HTTP Code: $($resLimitNeg.StatusCode) (Esperado: BadRequest)" -ForegroundColor $(if ($resLimitNeg.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) { "Green" } else { "Red" })
        if ($resLimitNeg.StatusCode -ne [System.Net.HttpStatusCode]::BadRequest) { exit 1 }

        # 2f. Parâmetro de Consulta Não Autorizado (?unauthorized_param=1)
        $resUnauthParam = $client.GetAsync("http://localhost:8080/api/v1/customers?unauthorized_param=1").Result
        Write-Host "  [+] GET /api/v1/customers?unauthorized_param=1 HTTP Code: $($resUnauthParam.StatusCode) (Esperado: BadRequest)" -ForegroundColor $(if ($resUnauthParam.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) { "Green" } else { "Red" })
        if ($resUnauthParam.StatusCode -ne [System.Net.HttpStatusCode]::BadRequest) { exit 1 }
    } finally {
        $client.Dispose()
        if (-not $proc.HasExited) { $proc.Kill() }
    }
}

function Test-SecurityLogin {
    Write-Host "`n[TEST 3] Validando Autenticação Estrita via POST Body JSON em SecurityApp..." -ForegroundColor Cyan
    $exePath = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-14-auth-jwt\SecurityApp.exe"
    $exeDir = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-14-auth-jwt"

    Get-Process -Name "SecurityApp" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    $proc = [System.Diagnostics.Process]::Start((New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = $exePath; WorkingDirectory = $exeDir; UseShellExecute = $false; CreateNoWindow = $true
    }))
    Start-Sleep -Seconds 3

    $client = New-Object System.Net.Http.HttpClient
    try {
        # 3a. Tentativa via Query String sem Body (Rejeitada)
        $resQueryStr = $client.PostAsync("http://localhost:8080/api/v1/auth/login?user=admin&pass=AdminSecret2026!", $null).Result
        Write-Host "  [+] POST Login QueryString Sem Body HTTP Code: $($resQueryStr.StatusCode) (Esperado: BadRequest)" -ForegroundColor $(if ($resQueryStr.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) { "Green" } else { "Red" })
        if ($resQueryStr.StatusCode -ne [System.Net.HttpStatusCode]::BadRequest) { exit 1 }

        # 3b. POST Body JSON com Senha Incorreta
        $bodyInvalid = New-Object System.Net.Http.StringContent('{"username":"admin","password":"wrong_password"}', [System.Text.Encoding]::UTF8, "application/json")
        $res401 = $client.PostAsync("http://localhost:8080/api/v1/auth/login", $bodyInvalid).Result
        Write-Host "  [+] POST Login Senha Incorreta HTTP Code: $($res401.StatusCode) (Esperado: Unauthorized)" -ForegroundColor $(if ($res401.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) { "Green" } else { "Red" })
        if ($res401.StatusCode -ne [System.Net.HttpStatusCode]::Unauthorized) { exit 1 }

        # 3c. POST Body JSON Válido
        $bodyValid = New-Object System.Net.Http.StringContent('{"username":"admin","password":"AdminSecret2026!"}', [System.Text.Encoding]::UTF8, "application/json")
        $res200 = $client.PostAsync("http://localhost:8080/api/v1/auth/login", $bodyValid).Result
        Write-Host "  [+] POST Login JSON Válido HTTP Code: $($res200.StatusCode) (Esperado: OK)" -ForegroundColor $(if ($res200.StatusCode -eq [System.Net.HttpStatusCode]::OK) { "Green" } else { "Red" })
        if ($res200.StatusCode -ne [System.Net.HttpStatusCode]::OK) { exit 1 }
    } finally {
        $client.Dispose()
        if (-not $proc.HasExited) { $proc.Kill() }
    }
}

function Test-RealtimeTenantHeader {
    Write-Host "`n[TEST 4] Validando autenticação de tenant em RealtimeApp..." -ForegroundColor Cyan
    $exePath = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-20-frontend-ssr-htmx\RealtimeApp.exe"
    $exeDir = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples\chapter-20-frontend-ssr-htmx"

    Get-Process -Name "RealtimeApp" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    $env:DEXT_DEMO_TENANT_ALPHA_TOKEN = "alpha_test_token"
    $env:DEXT_DEMO_TENANT_BETA_TOKEN = "beta_test_token"
    $proc = [System.Diagnostics.Process]::Start((New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = $exePath; WorkingDirectory = $exeDir; UseShellExecute = $false; CreateNoWindow = $true
    }))
    Start-Sleep -Seconds 3

    $client = New-Object System.Net.Http.HttpClient
    try {
        # 4a. Trigger sem Bearer token (rejeitado)
        $resNoHeader = $client.PostAsync("http://localhost:8080/api/v1/trigger-tenant-notification", $null).Result
        Write-Host "  [+] Trigger sem Bearer token: $($resNoHeader.StatusCode) (Esperado: Unauthorized)" -ForegroundColor $(if ($resNoHeader.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) { "Green" } else { "Red" })
        if ($resNoHeader.StatusCode -ne [System.Net.HttpStatusCode]::Unauthorized) { exit 1 }

        # 4b. Token inválido continua rejeitado.
        $reqInvalid = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, "http://localhost:8080/api/v1/trigger-tenant-notification")
        $reqInvalid.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", "invalid_token")
        $resInvalid = $client.SendAsync($reqInvalid).Result
        Write-Host "  [+] Trigger com token inválido: $($resInvalid.StatusCode) (Esperado: Unauthorized)" -ForegroundColor $(if ($resInvalid.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) { "Green" } else { "Red" })
        if ($resInvalid.StatusCode -ne [System.Net.HttpStatusCode]::Unauthorized) { exit 1 }

        # 4c. Tokens válidos são resolvidos para tenants pelo servidor.
        foreach ($token in @("alpha_test_token", "beta_test_token")) {
            $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, "http://localhost:8080/api/v1/trigger-tenant-notification")
            $req.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", $token)
            $res = $client.SendAsync($req).Result
            Write-Host "  [+] Trigger com token válido ($token): $($res.StatusCode) (Esperado: OK)" -ForegroundColor $(if ($res.StatusCode -eq [System.Net.HttpStatusCode]::OK) { "Green" } else { "Red" })
            if ($res.StatusCode -ne [System.Net.HttpStatusCode]::OK) { exit 1 }
        }
    } finally {
        $client.Dispose()
        if (-not $proc.HasExited) { $proc.Kill() }
    }
}

Test-HostingProbes
Start-Sleep -Seconds 2
Test-DataApiPolicy
Start-Sleep -Seconds 2
Test-SecurityLogin
Start-Sleep -Seconds 2
Test-RealtimeTenantHeader

Write-Host "`n[SUCESSO INTEGRAL] Todos os probes de observabilidade, políticas de allowlist e autenticação foram validados com 100% de êxito!" -ForegroundColor Green
