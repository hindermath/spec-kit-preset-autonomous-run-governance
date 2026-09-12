<#
.SYNOPSIS
Validiert eine ausdrueckliche autonome Liefermenge read-only.

Validates an explicit autonomous delivery set read-only.
.DESCRIPTION
Prueft entweder geaenderte getrackte Dateien plus benannte unversionierte
Dateien oder den exakten Staging-Kandidaten. Der Validator veraendert weder
Index noch Arbeitsbaum. Validates either changed tracked files plus named
untracked files or the exact staged candidate. It changes neither index nor
worktree.
.PARAMETER Repo
Git-Arbeitsbaum, dessen Liefermenge geprueft wird. Git worktree to validate.
.PARAMETER Intended
Repository-relative Lieferpfade. Ohne -Staged werden unversionierte Dateien
benannt; mit -Staged muss die Liste exakt dem physischen Indexkandidaten
einschliesslich beider Pfade einer Umbenennung entsprechen.
Repository-relative delivery paths. Without -Staged they name untracked files;
with -Staged the list must exactly match the physical index candidate, including
both paths of a rename.
.PARAMETER AllowHistoricalWhitespace
Explizit genehmigte historische Datei als repositoryrelativer Pfad plus
unveraenderter Roh-SHA-256 (`PATH=SHA256`). Nur fuer zugleich mit `-Intended`
benannte Dateien; wiederholbar. Explicitly approved historical file as a
repository-relative path plus unchanged raw SHA-256 (`PATH=SHA256`). Only for
files also named with `-Intended`; repeatable.
.PARAMETER Staged
Prueft den exakten, mit -Intended benannten Indexkandidaten. Historische
Whitespace-Ausnahmen gelten nur fuer neu hinzugefuegte Dateien und werden an
deren Indexbytes gebunden. Nur regulaere Index-Dateimodi sind erlaubt. Validates
the exact index candidate named with -Intended. Historical whitespace
allowances apply only to newly added files and bind their index bytes. Only
regular-file index modes are accepted.
.EXAMPLE
pwsh -NoProfile -File validate-autonomous-delivery-set.ps1 -Repo . -Intended specs/027/evidence.md
.EXAMPLE
pwsh -NoProfile -File validate-autonomous-delivery-set.ps1 -Repo . -Staged -Intended @('src/app.cs','specs/027/evidence.md')
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [string[]]$Intended = @(),
    [string[]]$AllowHistoricalWhitespace = @(),
    [switch]$Staged
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Python = Get-Command python3 -ErrorAction SilentlyContinue
if ($null -eq $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
if ($null -eq $Python) { Write-Error 'ERROR AEI001: python3 or python is required'; exit 2 }
$Arguments = @((Join-Path $PSScriptRoot 'autonomous-evidence-core.py'), 'delivery', '--repo', $Repo)
if ($Staged) { $Arguments += '--staged' }
foreach ($Path in $Intended) { $Arguments += @('--intended', $Path) }
foreach ($Allowance in $AllowHistoricalWhitespace) { $Arguments += @('--allow-historical-whitespace', $Allowance) }
& $Python.Source @Arguments
exit $LASTEXITCODE
