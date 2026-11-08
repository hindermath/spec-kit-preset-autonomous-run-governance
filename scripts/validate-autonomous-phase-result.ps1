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
.PARAMETER AttemptId
Optionaler erwarteter Versuch; der Runner uebergibt ihn fuer Replay-Schutz.
Optional expected attempt; the runner supplies it to prevent replay.
.PARAMETER ExitCode
Exitcode des bereits beendeten Phasenprozesses. Exit code of the completed phase process.
.PARAMETER ExpectedTasks
Vor dem Runner akzeptierte positive Aufgabenzahl. Positive task count accepted before runner execution.
.PARAMETER ExpectedPayload
Vor dem Runner festgelegter repository-relativer Artefaktpfad. Preaccepted repository-relative artifact path.
.PARAMETER GateExitCode
Exitcode einer unabhaengigen, lokal konfigurierten Nachpruefung. Exit code of an independent locally configured postflight.
.PARAMETER TaskManifest
Optionaler akzeptierter Aufgabenpfad fuer Implementierungsphasen. Optional accepted task path for implementation phases.
.PARAMETER TaskInventorySha
Vor dem Runner festgehaltener Hash der Task-Identitaeten. Task identity hash captured before the runner.
.EXAMPLE
pwsh -NoProfile -File validate-autonomous-phase-result.ps1 -Repo . -Result phase.result.json -PhaseId analyze -ExitCode 0 -ExpectedTasks 1 -ExpectedPayload specs/001-feature/plan.md -GateExitCode 0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repo,
    [Parameter(Mandatory)][string]$Result,
    [Parameter(Mandatory)][string]$PhaseId,
    [string]$AttemptId = '',
    [Parameter(Mandatory)][int]$ExitCode,
    [Parameter(Mandatory)][int]$ExpectedTasks,
    [Parameter(Mandatory)][string]$ExpectedPayload,
    [Parameter(Mandatory)][int]$GateExitCode,
    [string]$TaskManifest = '',
    [string]$TaskInventorySha = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Python = Get-Command python3 -ErrorAction SilentlyContinue
if ($null -eq $Python) { $Python = Get-Command python -ErrorAction SilentlyContinue }
if ($null -eq $Python) { Write-Error 'ERROR AEI001: python3 or python is required'; exit 2 }
$Arguments = @((Join-Path $PSScriptRoot 'autonomous-evidence-core.py'), 'phase', '--repo', $Repo, '--result', $Result, '--phase-id', $PhaseId, '--exit-code', [string]$ExitCode, '--expected-tasks', [string]$ExpectedTasks, '--expected-payload', $ExpectedPayload, '--gate-exit-code', [string]$GateExitCode)
if ($AttemptId) { $Arguments += @('--attempt-id', $AttemptId) }
if ($TaskManifest) { $Arguments += @('--task-manifest', $TaskManifest) }
if ($TaskInventorySha) { $Arguments += @('--task-inventory-sha', $TaskInventorySha) }
& $Python.Source @Arguments
exit $LASTEXITCODE
