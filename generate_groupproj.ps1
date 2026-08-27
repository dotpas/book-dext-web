param(
    [string]$ExamplesDir = "C:\dev\Dext\Docs\dext-developer-bookshelf\book\examples"
)

$GroupProjFile = Join-Path $ExamplesDir "DextBookExamples.groupproj"
$DprojFiles = Get-ChildItem -Path $ExamplesDir -Recurse -Filter "*.dproj" | Sort-Object Name

# Ensure unique dproj files by BaseName
$UniqueProjects = @{}
foreach ($Dproj in $DprojFiles) {
    if (-not $UniqueProjects.ContainsKey($Dproj.BaseName)) {
        $UniqueProjects[$Dproj.BaseName] = $Dproj
    }
}

$SortedList = $UniqueProjects.Values | Sort-Object Name

$Xml = [System.Text.StringBuilder]::new()
[void]$Xml.AppendLine('<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
[void]$Xml.AppendLine('    <PropertyGroup>')
[void]$Xml.AppendLine('        <ProjectGuid>{FD3D28FA-2596-4018-96CF-355200A95C1D}</ProjectGuid>')
[void]$Xml.AppendLine('    </PropertyGroup>')
[void]$Xml.AppendLine('    <ItemGroup>')

foreach ($Proj in $SortedList) {
    $RelPath = $Proj.FullName.Substring($ExamplesDir.Length + 1)
    [void]$Xml.AppendLine("        <Projects Include=`"$RelPath`">")
    [void]$Xml.AppendLine('            <Dependencies/>')
    [void]$Xml.AppendLine('        </Projects>')
}

[void]$Xml.AppendLine('    </ItemGroup>')
[void]$Xml.AppendLine('    <ProjectExtensions>')
[void]$Xml.AppendLine('        <Borland.Personality>Default.Personality.12</Borland.Personality>')
[void]$Xml.AppendLine('        <Borland.ProjectType/>')
[void]$Xml.AppendLine('        <BorlandProject>')
[void]$Xml.AppendLine('            <Default.Personality/>')
[void]$Xml.AppendLine('        </BorlandProject>')
[void]$Xml.AppendLine('    </ProjectExtensions>')

foreach ($Proj in $SortedList) {
    $RelPath = $Proj.FullName.Substring($ExamplesDir.Length + 1)
    $Target = $Proj.BaseName
    [void]$Xml.AppendLine("    <Target Name=`"$Target`">")
    [void]$Xml.AppendLine("        <MSBuild Projects=`"$RelPath`"/>")
    [void]$Xml.AppendLine('    </Target>')
    [void]$Xml.AppendLine("    <Target Name=`"$Target`:Clean`">")
    [void]$Xml.AppendLine("        <MSBuild Projects=`"$RelPath`" Targets=`"Clean`"/>")
    [void]$Xml.AppendLine('    </Target>')
    [void]$Xml.AppendLine("    <Target Name=`"$Target`:Make`">")
    [void]$Xml.AppendLine("        <MSBuild Projects=`"$RelPath`" Targets=`"Make`"/>")
    [void]$Xml.AppendLine('    </Target>')
}

$AllTargets = ($SortedList | ForEach-Object { $_.BaseName }) -join ';'
$AllCleanTargets = ($SortedList | ForEach-Object { $_.BaseName + ':Clean' }) -join ';'
$AllMakeTargets = ($SortedList | ForEach-Object { $_.BaseName + ':Make' }) -join ';'

[void]$Xml.AppendLine('    <Target Name="Build">')
[void]$Xml.AppendLine("        <CallTarget Targets=`"$AllTargets`"/>")
[void]$Xml.AppendLine('    </Target>')
[void]$Xml.AppendLine('    <Target Name="Clean">')
[void]$Xml.AppendLine("        <CallTarget Targets=`"$AllCleanTargets`"/>")
[void]$Xml.AppendLine('    </Target>')
[void]$Xml.AppendLine('    <Target Name="Make">')
[void]$Xml.AppendLine("        <CallTarget Targets=`"$AllMakeTargets`"/>")
[void]$Xml.AppendLine('    </Target>')
[void]$Xml.AppendLine('</Project>')

Set-Content -Path $GroupProjFile -Value $Xml.ToString() -Encoding UTF8
Write-Host "[SUCESSO] DextBookExamples.groupproj atualizado com $($SortedList.Count) projetos!" -ForegroundColor Green
