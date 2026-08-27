param(
    [string]$ExamplesDir = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples"
)

$TemplatePath = Join-Path $ExamplesDir "chapter-01-first-api\Chapter01_FirstAPI.dproj"
$Template = Get-Content $TemplatePath -Raw

$DprFiles = Get-ChildItem -Path $ExamplesDir -Recurse -Filter "*.dpr" | Sort-Object Name

foreach ($Dpr in $DprFiles) {
    $DprojPath = [System.IO.Path]::ChangeExtension($Dpr.FullName, ".dproj")
    if (-not (Test-Path $DprojPath)) {
        $BaseName = $Dpr.BaseName
        $Guid = [guid]::NewGuid().ToString("B").ToUpper()
        $Content = $Template -replace "Chapter01_FirstAPI\.dpr", ($BaseName + ".dpr")
        $Content = $Content -replace "Chapter01_FirstAPI", $BaseName
        $Content = $Content -replace "\{58DD2BF5-1A2E-42D2-A20F-4C59133981E6\}", $Guid
        Set-Content -Path $DprojPath -Value $Content -Encoding UTF8
        Write-Host "[CRIADO] $DprojPath" -ForegroundColor Green
    } else {
        Write-Host "[EXISTE] $DprojPath" -ForegroundColor Gray
    }
}
