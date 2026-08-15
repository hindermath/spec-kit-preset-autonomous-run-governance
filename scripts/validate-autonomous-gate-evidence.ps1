<#
.SYNOPSIS
Validiert lebenszyklusgebundene autonome Gate-Evidence read-only.

Validates lifecycle-bound autonomous gate evidence read-only.
.PARAMETER Requirements
Akzeptierte Gate-Anforderungen. Accepted gate requirements.
.PARAMETER Evidence
PreMerge-, PostMerge- oder historische Evidence. Lifecycle or historical evidence.
.PARAMETER Head
Vollstaendiger gepruefter Git-Head. Full reviewed Git head.
.PARAMETER MergeCommit
Erwarteter Merge-Commit fuer PostMerge. Expected merge commit for PostMerge.
.PARAMETER Historical
Erlaubt Schema 1.0 ausschliesslich fuer Audit, nie als Mergefreigabe.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Requirements,
    [Parameter(Mandatory)][string]$Evidence,
    [Parameter(Mandatory)][string]$Head,
    [string]$MergeCommit = '',
    [switch]$Historical
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Python = Get-Command python3 -ErrorAction SilentlyContinue
if ($null -eq $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
if ($null -eq $Python) { Write-Error 'ERROR AEI001: python3 or python is required'; exit 2 }
$Arguments = @(
    (Join-Path $PSScriptRoot 'autonomous-evidence-core.py'), 'gate',
    '--requirements', $Requirements, '--evidence', $Evidence, '--head', $Head
)
if ($MergeCommit) { $Arguments += @('--merge-commit', $MergeCommit) }
if ($Historical) { $Arguments += '--historical' }
& $Python.Source @Arguments
exit $LASTEXITCODE
