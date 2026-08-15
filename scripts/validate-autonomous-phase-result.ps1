<#
.SYNOPSIS
Validiert den semantischen Abschluss einer gerouteten Phase read-only.

Validates semantic completion for one routed phase read-only.
.DESCRIPTION
Ein Prozess-Exitcode null reicht nicht aus. Das Skript prueft Phase, Versuch,
Aufgaben, Gates und den normalisierten Payload-Hash. A zero process exit code is
not sufficient. The script validates phase, attempt, tasks, gates, and the
normalized payload hash.
.PARAMETER Repo
Repository-Wurzel fuer den Payload-Pfad. Repository root for the payload path.
.PARAMETER Result
Strukturierte JSON-Ergebnisdatei der Phase. Structured JSON phase-result file.
.PARAMETER PhaseId
Erwartete stabile Phasen-ID. Expected stable phase ID.
.PARAMETER ExitCode
Exitcode des bereits beendeten Phasenprozesses. Exit code of the completed phase process.
.EXAMPLE
pwsh -NoProfile -File validate-autonomous-phase-result.ps1 -Repo . -Result phase.result.json -PhaseId analyze -ExitCode 0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Result,
    [Parameter(Mandatory)][string]$PhaseId,
    [Parameter(Mandatory)][int]$ExitCode
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Python = Get-Command python3 -ErrorAction SilentlyContinue
if ($null -eq $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
if ($null -eq $Python) { Write-Error 'ERROR AEI001: python3 or python is required'; exit 2 }
& $Python.Source (Join-Path $PSScriptRoot 'autonomous-evidence-core.py') phase --repo $Repo --result $Result --phase-id $PhaseId --exit-code $ExitCode
exit $LASTEXITCODE
