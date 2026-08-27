# =============================================================================
# test_all_examples.ps1 - Master Test Suite Runner for All Dext Examples
# Location: Docs/dext-developer-bookshelf/book/examples/test_all_examples.ps1
# =============================================================================

$ErrorActionPreference = "Continue"
$ExamplesDir = $PSScriptRoot

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "            Dext Book Example Test Suite Validator                  " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Examples Directory: $ExamplesDir" -ForegroundColor Gray
Write-Host "--------------------------------------------------------------------"

$TestScripts = Get-ChildItem -Path $ExamplesDir -Recurse -Filter "Test.*.ps1" | Sort-Object Name

$Passed = @()
$Failed = @()

foreach ($Script in $TestScripts) {
    $ProjName = $Script.BaseName.Replace("Test.", "")
    Write-Host "`n[EXECUTANDO TESTE] $ProjName ($($Script.Directory.Name))..." -ForegroundColor Yellow
    
    $PInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
        FileName = "powershell.exe"
        Arguments = "-ExecutionPolicy Bypass -File `"$($Script.FullName)`" -AutoClose"
        WorkingDirectory = $Script.DirectoryName
        UseShellExecute = $false
        RedirectStandardOutput = $true
        RedirectStandardError = $true
        CreateNoWindow = $true
    }

    $Process = [System.Diagnostics.Process]::Start($PInfo)
    $StdOut = $Process.StandardOutput.ReadToEnd()
    $StdErr = $Process.StandardError.ReadToEnd()
    $Process.WaitForExit()

    if ($Process.ExitCode -eq 0) {
        Write-Host "  [SUCESSO] $ProjName passou em todos os testes e validacoes!" -ForegroundColor Green
        $Passed += $ProjName
    } else {
        Write-Host "  [FALHA] $ProjName falhou no teste de integracao!" -ForegroundColor Red
        Write-Host $StdOut -ForegroundColor DarkGray
        Write-Host $StdErr -ForegroundColor Red
        $Failed += $ProjName
    }
}

Write-Host "`n====================================================================" -ForegroundColor Cyan
Write-Host "RESULTADO DA VALIDACAO DOS TESTES DOS EXEMPLOS DO LIVRO:" -ForegroundColor Cyan
Write-Host "Sucesso: $($Passed.Count) | Falhas: $($Failed.Count)" -ForegroundColor $(if ($Failed.Count -eq 0) { "Green" } else { "Red" })

if ($Failed.Count -eq 0) {
    Write-Host "`nTODOS OS $($Passed.Count) PROJETOS PASSARAM EM SEUS SCRIPTS DE TESTE COM EXITO!" -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nPROJETOS COM FALHAS DE TESTE:" -ForegroundColor Red
    foreach ($F in $Failed) {
        Write-Host "  - $F" -ForegroundColor Red
    }
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
