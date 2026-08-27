# =============================================================================
# compile_all_examples.ps1 - Automated Strict Compiler Validator for Dext Examples
# Location: Docs/dext-developer-bookshelf/book/examples/compile_all_examples.ps1
# =============================================================================
param(
    [string]$CompilerPath = "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc64.exe"
)

$ErrorActionPreference = "Continue"

$ScriptDir = $PSScriptRoot
$SourcesDir = "C:\dev\Dext\DextRepository\Sources"
$ExamplesDir = $ScriptDir
$BuildDcuDir = Join-Path $ScriptDir "build_dcu"

if (-not (Test-Path $CompilerPath)) {
    $CompilerPath = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\dcc64.exe"
}

# Create single persistent DCU directory before loop
if (-not (Test-Path $BuildDcuDir)) {
    New-Item -ItemType Directory -Path $BuildDcuDir -Force | Out-Null
}

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "            Dext Book Example Compiler Validator (Strict)           " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Compilador: $CompilerPath" -ForegroundColor Gray
Write-Host "Sources:    $SourcesDir" -ForegroundColor Gray
Write-Host "Exemplos:   $ExamplesDir" -ForegroundColor Gray
Write-Host "Build DCU:  $BuildDcuDir" -ForegroundColor Gray
Write-Host "--------------------------------------------------------------------"

$SourceDirs = Get-ChildItem -Path $SourcesDir -Recurse -Directory | Select-Object -ExpandProperty FullName
$AllSearchDirs = @($SourcesDir) + $SourceDirs
$SearchPath = $AllSearchDirs -join ';'

$DprFiles = Get-ChildItem -Path $ExamplesDir -Recurse -File | Where-Object { $_.Extension -ieq ".dpr" } | Sort-Object Name

$SuccessCount = 0
$FailureCount = 0
$FailedProjects = @()

foreach ($Dpr in $DprFiles) {
    $ProjName = $Dpr.Name
    $ProjDir = $Dpr.DirectoryName
    $ExpectedExe = [System.IO.Path]::Combine($ProjDir, $Dpr.BaseName + ".exe")

    Write-Host "`n[COMPILANDO] $ProjName ($($Dpr.Directory.Name))..." -ForegroundColor Yellow
    
    $BuildStartedAt = Get-Date

    # Remove previous binary to prevent false positives
    if (Test-Path $ExpectedExe) {
        Remove-Item -Path $ExpectedExe -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 50
    }

    # Clean any old DCU files in project folder
    Get-ChildItem -Path $ProjDir -Filter "*.dcu" | Remove-Item -Force -ErrorAction SilentlyContinue

    # Create project-isolated DCU directory to prevent file locking collisions
    $ProjectDcuDir = [System.IO.Path]::Combine($ProjDir, "dcu")
    if (-not (Test-Path $ProjectDcuDir)) {
        New-Item -ItemType Directory -Path $ProjectDcuDir -Force | Out-Null
    }

    $LogFile = [System.IO.Path]::Combine($ProjDir, "build.log")
    
    $ArgList = @(
        "-B",
        "-Q",
        "-I$SearchPath",
        "-U$SearchPath",
        "-E$ProjDir",
        "-N$ProjectDcuDir",
        $Dpr.FullName
    )

    $PInfo = New-Object System.Diagnostics.ProcessStartInfo
    $PInfo.FileName = $CompilerPath
    $PInfo.Arguments = ($ArgList | ForEach-Object { "`"$_`"" }) -join ' '
    $PInfo.UseShellExecute = $false
    $PInfo.RedirectStandardOutput = $true
    $PInfo.RedirectStandardError = $true
    $PInfo.CreateNoWindow = $true

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $PInfo
    [void]$Process.Start()

    $StdOut = $Process.StandardOutput.ReadToEnd()
    $StdErr = $Process.StandardError.ReadToEnd()
    $Process.WaitForExit()

    $CombinedLog = $StdOut + "`n" + $StdErr
    Set-Content -Path $LogFile -Value $CombinedLog

    $HasCompilerError = $CombinedLog -match '(?m)\b(?:Error|Fatal):'
    $ExeWasProduced = (Test-Path $ExpectedExe) -and ((Get-Item $ExpectedExe).LastWriteTime -ge $BuildStartedAt)

    if (($Process.ExitCode -eq 0) -and (-not $HasCompilerError) -and $ExeWasProduced) {
        Write-Host "  [SUCESSO] $ProjName compilou e gerou executavel com exito." -ForegroundColor Green
        $SuccessCount++
    } else {
        Write-Host "  [FALHA DE COMPILACAO] $ProjName falhou na compilacao ou nao gerou binario!" -ForegroundColor Red
        Write-Host "  Consulte o log de build: $LogFile" -ForegroundColor Red
        $FailureCount++
        $FailedProjects += $ProjName
    }
}

Write-Host "`n====================================================================" -ForegroundColor Cyan
Write-Host "RESULTADO DA VALIDACAO ESTRITA DOS EXEMPLOS:" -ForegroundColor Cyan
Write-Host "Sucesso: $SuccessCount | Falhas: $FailureCount" -ForegroundColor $(if ($FailureCount -eq 0) { "Green" } else { "Red" })

if ($FailureCount -eq 0) {
    Write-Host "TODOS OS $SuccessCount PROJETOS COMPILARAM E GERARAM EXECUTAVEIS COM SUCESSO!" -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "PROJETOS COM ERRO:" -ForegroundColor Red
    foreach ($Proj in $FailedProjects) {
        Write-Host "  - $Proj" -ForegroundColor Red
    }
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
