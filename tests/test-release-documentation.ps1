#Requires -Version 7.3
<#
.SYNOPSIS
    Release-Dokumentation pruefen / Test release documentation.
.DESCRIPTION
    DE: Statische Vertragspruefung und bei Statistics eigene Offline-Doubles.
    Keine Modellaufrufe, echte Downloads, Installation oder Provider-Aktionen.
    EN: Static contracts and owned offline doubles for Statistics. No model
    calls, real downloads, installations or provider operations.
.EXAMPLE
    pwsh -NoProfile -File tests/test-release-documentation.ps1
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$metadata=[IO.File]::ReadAllText((Join-Path $root 'preset.yml'))
$id=[regex]::Match($metadata,'(?m)^  id: "([^"]+)"').Groups[1].Value
$version=[regex]::Match($metadata,'(?m)^  version: "([^"]+)"').Groups[1].Value
$readme=[IO.File]::ReadAllText((Join-Path $root 'README.md'))
$priorities=@{'secure-development-assurance-governance'=15;'intake-authoring-governance'=64;'autonomous-run-governance'=70;'parallel-autonomous-run-governance'=80;'project-statistics-governance'=90}
$assertions=0
function Assert-Documentation {
    param([bool]$Condition,[string]$Message)
    if(-not $Condition){throw "FAIL: $Message"}
    $script:assertions++
}
$url="https://github.com/hindermath/spec-kit-preset-$id/archive/refs/tags/v$version.zip"
$line="specify preset add --from $url --priority $($priorities[$id])"
Assert-Documentation ([regex]::IsMatch($readme,'(?m)^\s*'+[regex]::Escape($line)+'\r?$')) 'exact release install command on one line'
Assert-Documentation (Test-Path -LiteralPath (Join-Path $root "docs/release-$version-validation.md")) 'current release preparation record exists'
switch($id){
{$_ -cin @('autonomous-run-governance','parallel-autonomous-run-governance')} {
        $guide=[IO.File]::ReadAllText((Join-Path $root 'docs/getting-started.md'))
        Assert-Documentation ([regex]::IsMatch($guide,'(?m)^\s*'+[regex]::Escape($line)+'\r?$')) 'first-run guide installs current release on one line'
        $ownArchives=[regex]::Matches($guide,'spec-kit-preset-'+[regex]::Escape($id)+'/archive/refs/tags/v([^/\s]+)\.zip')
        Assert-Documentation ($ownArchives.Count -gt 0) 'first-run guide contains own archive'
        foreach($archive in $ownArchives){Assert-Documentation ($archive.Groups[1].Value -ceq $version) 'first-run examples never silently install previous own version'}
        if($id -ceq 'parallel-autonomous-run-governance'){
            foreach($text in @($readme,$guide)){
                Assert-Documentation ($text.Contains('spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.4.6.zip')) 'current recommended worker pair'
                Assert-Documentation (-not $text.Contains('spec-kit-preset-autonomous-run-governance/archive/refs/tags/v0.3.6.zip')) 'old worker archive not presented as current install'
            }
        }
    }
}
"PASS: $assertions release-documentation assertions; no model calls or network downloads."
exit 0
