<#
.SYNOPSIS
Validiert eine ausdrueckliche autonome Liefermenge read-only.

Validates an explicit autonomous delivery set read-only.
.DESCRIPTION
Prueft geaenderte getrackte Dateien und ausdruecklich benannte unversionierte
Dateien, meldet sachfremde unversionierte Pfade und veraendert weder Index noch
Arbeitsbaum. Checks changed tracked files and explicitly named untracked files,
reports unrelated untracked paths, and changes neither index nor worktree.
.PARAMETER Repo
Git-Arbeitsbaum, dessen Liefermenge geprueft wird. Git worktree to validate.
.PARAMETER Intended
Repository-relative, nicht ignorierte unversionierte Dateien, die zur Lieferung
gehoeren. Repository-relative, non-ignored untracked files intended for delivery.
.EXAMPLE
pwsh -NoProfile -File validate-autonomous-delivery-set.ps1 -Repo . -Intended specs/027/evidence.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [string[]]$Intended = @()
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Python = Get-Command python3 -ErrorAction SilentlyContinue
if ($null -eq $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
if ($null -eq $Python) { Write-Error 'ERROR AEI001: python3 or python is required'; exit 2 }
$Arguments = @((Join-Path $PSScriptRoot 'autonomous-evidence-core.py'), 'delivery', '--repo', $Repo)
foreach ($Path in $Intended) { $Arguments += @('--intended', $Path) }
& $Python.Source @Arguments
exit $LASTEXITCODE
