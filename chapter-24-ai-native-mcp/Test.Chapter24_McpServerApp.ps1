# =============================================================================
# Test.Chapter24_McpServerApp.ps1 - MCP Protocol & Provider Tools Execution Validation
# Project: Chapter24_McpServerApp.dpr (Chapter 24)
# =============================================================================
param(
    [switch]$AutoClose,
    [switch]$NoAutoLaunch
)

$ErrorActionPreference = "Continue"
$ScriptDir = $PSScriptRoot
$ExePath = Join-Path $ScriptDir "Chapter24_McpServerApp.exe"

Write-Host "[RUN] Executing Chapter24_McpServerApp.exe (MCP Protocol Server)..." -ForegroundColor Yellow
$PInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
    FileName = $ExePath
    WorkingDirectory = $ScriptDir
    UseShellExecute = $false
    RedirectStandardOutput = $true
    RedirectStandardError = $true
    CreateNoWindow = $true
}
$PInfo.EnvironmentVariables["DEXT_MCP_AGENT_TOKEN"] = "secret_agent_token_2026"

$Process = [System.Diagnostics.Process]::Start($PInfo)
$StdOut = $Process.StandardOutput.ReadToEnd()
$StdErr = $Process.StandardError.ReadToEnd()
$Process.WaitForExit()

Write-Host "`n--- Execution Output ---" -ForegroundColor Gray
Write-Host $StdOut -ForegroundColor White

$Success = $true
if ($Process.ExitCode -ne 0) {
    Write-Host "[FAIL] Process exited with code $($Process.ExitCode)" -ForegroundColor Red
    $Success = $false
}

if ($StdOut -notmatch "SUCESSO" -and $StdOut -notmatch "Secret Store validados") {
    Write-Host "[FAIL] MCP Protocol server tool execution pattern not matched." -ForegroundColor Red
    $Success = $false
}

if ($Success) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host " SUCCESS: Chapter24_McpServerApp AI MCP protocol server validated!           " -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n====================================================================" -ForegroundColor Red
    Write-Host " FAILURE: Chapter24_McpServerApp execution validation failed.                 " -ForegroundColor Red
    Write-Host "====================================================================" -ForegroundColor Red
    exit 1
}
