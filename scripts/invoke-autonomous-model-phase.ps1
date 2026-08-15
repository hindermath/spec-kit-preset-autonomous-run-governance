#Requires -Version 7.0
<#
.SYNOPSIS
    Fuehrt genau eine modellgeroutete Phase eines autonomen Spec-Kit-Laufs aus.

.DESCRIPTION
    DE: Loest die staerkste agentenneutrale Routing-Rolle fuer ein Preset-
    Kommando auf, bindet sie an ein lokales Runner-Profil und fuehrt Preflight
    und Phase ohne Shell-Evaluation aus. Modellwechsel erfolgen nur zwischen
    Prozessen. Fehlende oder nicht verfuegbare Profile blockieren fail-closed.

    EN: Resolves the strongest agent-neutral routing role for a preset command,
    binds it to a local runner profile, and executes preflight and phase without
    shell evaluation. Model changes occur only between processes. Missing or
    unavailable profiles fail closed.

.PARAMETER Action
    Validate, Run oder Status.

.PARAMETER State
    Feature-lokaler autonomous-run-state.json.

.PARAMETER RunnerConfig
    Lokale, nicht versionierte JSON-Datei mit Agent- und Modellprofilen.

.PARAMETER RoutingRoot
    Verzeichnis mit installierten Presets und model-routing.json-Dateien.

.PARAMETER PhaseId
    Stabile ID der bei Run auszufuehrenden Phase.

.PARAMETER Worktree
    Repository beziehungsweise Worktree fuer den Agentenprozess.

.PARAMETER Prompt
    Zusaetzlicher, nicht geheimer Phasenauftrag.

.PARAMETER PromptFile
    Alternative UTF-8-Datei mit dem zusaetzlichen Phasenauftrag.

.PARAMETER OutputDirectory
    Lokaler, nicht versionierter Ergebnis- und Logbereich.

.PARAMETER OutputFormat
    Json oder barrierearmer Text.

.EXAMPLE
    pwsh -NoProfile -File scripts/invoke-autonomous-model-phase.ps1 -Action Validate -State specs/025-feature/autonomous-run-state.json -RunnerConfig ~/.home-baseline/spec-kit/runner-profiles.local.json

.EXAMPLE
    pwsh -NoProfile -File scripts/invoke-autonomous-model-phase.ps1 -Action Run -State specs/025-feature/autonomous-run-state.json -RunnerConfig ~/.home-baseline/spec-kit/runner-profiles.local.json -PhaseId plan-review -Prompt 'Review the accepted plan.'
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Validate', 'Run', 'Status')]
    [string] $Action,

    [Parameter(Mandatory)]
    [string] $State,

    [string] $RunnerConfig = '',
    [string] $RoutingRoot = '',
    [string] $PhaseId = '',
    [string] $Worktree = '',
    [string] $Prompt = '',
    [string] $PromptFile = '',
    [string] $OutputDirectory = '',
    [ValidateSet('Json', 'Text')]
    [string] $OutputFormat = 'Json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:AllowedRoles = @(
    'script-only',
    'fast-mechanical',
    'long-running-implementation',
    'coding-review',
    'frontier-reasoning'
)
$script:RoleRank = @{
    'script-only' = 0
    'fast-mechanical' = 10
    'long-running-implementation' = 20
    'coding-review' = 30
    'frontier-reasoning' = 40
}
$script:AllowedPhaseStatuses = @(
    'Pending', 'Running', 'Completed', 'Blocked', 'Failed', 'NeedsRevalidation'
)

function Assert-AMRCondition {
    param(
        [Parameter(Mandatory)][bool] $Condition,
        [Parameter(Mandatory)][string] $Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Read-AMRJson {
    param([Parameter(Mandatory)][string] $Path)

    Assert-AMRCondition (Test-Path -LiteralPath $Path -PathType Leaf) "JSON-Datei fehlt: $Path"
    try {
        return Get-Content -LiteralPath $Path -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
    } catch {
        throw "Ungueltiges UTF-8-JSON in ${Path}: $($_.Exception.Message)"
    }
}

function Write-AMRJsonAtomic {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)] $Value
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    $temporaryPath = "${Path}.tmp.$PID"
    try {
        $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $temporaryPath -Encoding utf8NoBOM
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    } finally {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-AMRRepositoryRoot {
    param([Parameter(Mandatory)][string] $StatePath)

    $featureDirectory = Split-Path -Parent ([IO.Path]::GetFullPath($StatePath))
    $specsDirectory = Split-Path -Parent $featureDirectory
    return Split-Path -Parent $specsDirectory
}

function Get-AMRRoutingCatalog {
    param([Parameter(Mandatory)][string] $Root)

    Assert-AMRCondition (Test-Path -LiteralPath $Root -PathType Container) "RoutingRoot fehlt: $Root"
    $effective = @{}
    $sources = @{}
    $catalogPaths = @(Get-ChildItem -LiteralPath $Root -Filter 'model-routing.json' -File -Recurse)
    Assert-AMRCondition ($catalogPaths.Count -gt 0) "Keine model-routing.json unter $Root gefunden."

    foreach ($catalogPath in $catalogPaths) {
        $catalog = Read-AMRJson $catalogPath.FullName
        Assert-AMRCondition ([string] $catalog.schemaVersion -eq '1.0') "Routing-Schema muss 1.0 sein: $($catalogPath.FullName)"
        Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $catalog.presetId)) "presetId fehlt: $($catalogPath.FullName)"
        Assert-AMRCondition ([string] $catalog.fallbackPolicy -eq 'fail-closed') "fallbackPolicy muss fail-closed sein: $($catalogPath.FullName)"
        Assert-AMRCondition ($catalog.commands -is [hashtable]) "commands muss ein Objekt sein: $($catalogPath.FullName)"
        Assert-AMRCondition ($script:AllowedRoles -contains [string] $catalog.defaultRole) "Ungueltige defaultRole: $($catalogPath.FullName)"

        foreach ($entry in $catalog.commands.GetEnumerator()) {
            $commandName = [string] $entry.Key
            $roleName = [string] $entry.Value
            Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace($commandName)) "Leerer Kommandoname: $($catalogPath.FullName)"
            Assert-AMRCondition ($script:AllowedRoles -contains $roleName) "Ungueltige Rolle '$roleName' fuer $commandName"
            if (-not $effective.ContainsKey($commandName) -or
                $script:RoleRank[$roleName] -gt $script:RoleRank[[string] $effective[$commandName]]) {
                $effective[$commandName] = $roleName
            }
            if (-not $sources.ContainsKey($commandName)) {
                $sources[$commandName] = @()
            }
            $sources[$commandName] = @($sources[$commandName]) + [ordered]@{
                presetId = [string] $catalog.presetId
                role = $roleName
            }
        }
    }

    return [ordered]@{
        commands = $effective
        sources = $sources
    }
}

function Get-AMRPhase {
    param(
        [Parameter(Mandatory)][hashtable] $StateData,
        [string] $RequestedPhaseId = ''
    )

    Assert-AMRCondition ($StateData.routing -is [hashtable]) 'State.routing fehlt.'
    Assert-AMRCondition ([string] $StateData.routing.policy -eq 'balanced-v1') 'State.routing.policy muss balanced-v1 sein.'
    Assert-AMRCondition ([string] $StateData.routing.fallbackPolicy -eq 'fail-closed') 'State.routing.fallbackPolicy muss fail-closed sein.'
    Assert-AMRCondition ($StateData.routing.phases -is [object[]]) 'State.routing.phases muss ein Array sein.'

    $phaseIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $selected = $null
    foreach ($phase in @($StateData.routing.phases)) {
        Assert-AMRCondition ($phase -is [hashtable]) 'Jede Routing-Phase muss ein Objekt sein.'
        $currentId = [string] $phase.phaseId
        Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace($currentId)) 'Routing phaseId fehlt.'
        Assert-AMRCondition ($phaseIds.Add($currentId)) "Doppelte routing phaseId: $currentId"
        Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $phase.command)) "Routing command fehlt: $currentId"
        Assert-AMRCondition ($script:AllowedRoles -contains [string] $phase.routingRole) "Ungueltige routingRole: $currentId"
        Assert-AMRCondition ($script:AllowedPhaseStatuses -contains [string] $phase.status) "Ungueltiger Phasenstatus: $currentId"
        if ($currentId -eq $RequestedPhaseId) {
            $selected = $phase
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($RequestedPhaseId)) {
        Assert-AMRCondition ($null -ne $selected) "Routing-Phase nicht gefunden: $RequestedPhaseId"
    }
    return $selected
}

function Assert-AMRPhaseContract {
    param(
        [Parameter(Mandatory)][hashtable] $StateData,
        [Parameter(Mandatory)][hashtable] $Catalog
    )

    [void](Get-AMRPhase $StateData '')
    foreach ($phase in @($StateData.routing.phases)) {
        $commandName = [string] $phase.command
        Assert-AMRCondition $Catalog.commands.ContainsKey($commandName) "Kein Routing-Vertrag fuer Kommando: $commandName"
        $effectiveRole = [string] $Catalog.commands[$commandName]
        Assert-AMRCondition ([string] $phase.routingRole -eq $effectiveRole) "Routing-Rolle fuer $commandName muss '$effectiveRole' sein."
        $dependencies = if ($phase.ContainsKey('dependsOn')) { @($phase.dependsOn) } else { @() }
        foreach ($dependency in $dependencies) {
            Assert-AMRCondition (@($StateData.routing.phases | Where-Object { [string] $_.phaseId -eq [string] $dependency }).Count -eq 1) "Unbekannte Phasenabhaengigkeit '$dependency'."
        }
    }
}

function Get-AMRRunnerProfile {
    param(
        [Parameter(Mandatory)][hashtable] $RunnerData,
        [Parameter(Mandatory)][hashtable] $Phase
    )

    Assert-AMRCondition ([string] $RunnerData.schemaVersion -in @('1.0', '1.1', '2.0')) 'RunnerConfig schemaVersion muss 1.0, 1.1 oder 2.0 sein.'
    Assert-AMRCondition ($RunnerData.profiles -is [hashtable]) 'RunnerConfig.profiles muss ein Objekt sein.'
    $phaseProfile = if ($Phase.ContainsKey('runnerProfile')) { [string] $Phase.runnerProfile } else { 'N/A' }
    if (-not [string]::IsNullOrWhiteSpace($phaseProfile) -and $phaseProfile -ne 'N/A') {
        Assert-AMRCondition $RunnerData.profiles.ContainsKey($phaseProfile) "Runner-Profil fehlt: $phaseProfile"
        $profileName = $phaseProfile
    } else {
        $matching = @($RunnerData.profiles.GetEnumerator() | Where-Object {
            [string] $_.Value.routingRole -eq [string] $Phase.routingRole
        })
        Assert-AMRCondition ($matching.Count -eq 1) "Routing-Rolle '$($Phase.routingRole)' benoetigt genau ein lokales Runner-Profil."
        $profileName = [string] $matching[0].Key
    }

    $runnerProfileData = $RunnerData.profiles[$profileName]
    Assert-AMRCondition ([string] $runnerProfileData.routingRole -eq [string] $Phase.routingRole) "Runner-Profil '$profileName' hat die falsche routingRole."
    Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $runnerProfileData.agentFamily)) "agentFamily fehlt: $profileName"
    Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $runnerProfileData.executable)) "executable fehlt: $profileName"
    Assert-AMRCondition ($runnerProfileData.arguments -is [object[]]) "arguments muss ein Array sein: $profileName"
    Assert-AMRCondition ([string] $Phase.routingRole -ne 'script-only') "script-only-Phase '$($Phase.phaseId)' muss direkt ohne Modellprozess ausgefuehrt werden."
    Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $runnerProfileData.model)) "model fehlt fuer fail-closed Profil: $profileName"
    Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $runnerProfileData.reasoningEffort)) "reasoningEffort fehlt fuer fail-closed Profil: $profileName"
    Assert-AMRCondition ($runnerProfileData.preflight -is [hashtable]) "preflight fehlt fuer fail-closed Profil: $profileName"
    Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $runnerProfileData.preflight.executable)) "preflight.executable fehlt: $profileName"
    Assert-AMRCondition ($runnerProfileData.preflight.arguments -is [object[]]) "preflight.arguments muss ein Array sein: $profileName"
    Assert-AMRCondition ($null -ne (Get-Command ([string] $runnerProfileData.executable) -ErrorAction SilentlyContinue)) "Runner executable nicht gefunden: $($runnerProfileData.executable)"
    Assert-AMRCondition ($null -ne (Get-Command ([string] $runnerProfileData.preflight.executable) -ErrorAction SilentlyContinue)) "Preflight executable nicht gefunden: $($runnerProfileData.preflight.executable)"

    return [ordered]@{
        name = $profileName
        data = $runnerProfileData
    }
}

function ConvertTo-AMRArguments {
    param(
        [Parameter(Mandatory)][object[]] $Arguments,
        [Parameter(Mandatory)][hashtable] $Values
    )

    $resolved = [Collections.Generic.List[string]]::new()
    foreach ($argument in $Arguments) {
        $value = [string] $argument
        foreach ($entry in $Values.GetEnumerator()) {
            $value = $value.Replace("{$($entry.Key)}", [string] $entry.Value)
        }
        $resolved.Add($value)
    }
    return $resolved.ToArray()
}

function Invoke-AMRCommand {
    param(
        [Parameter(Mandatory)][hashtable] $CommandProfile,
        [Parameter(Mandatory)][hashtable] $Values,
        [Parameter(Mandatory)][string] $WorkingDirectory
    )

    $arguments = ConvertTo-AMRArguments @($CommandProfile.arguments) $Values
    Push-Location -LiteralPath $WorkingDirectory
    try {
        $output = @(& ([string] $CommandProfile.executable) @arguments 2>&1)
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    } finally {
        Pop-Location
    }
    return [ordered]@{
        exitCode = $exitCode
        output = @($output | ForEach-Object { [string] $_ })
    }
}

function Set-AMRBlockedState {
    param(
        [Parameter(Mandatory)][hashtable] $StateData,
        [Parameter(Mandatory)][hashtable] $Phase,
        [Parameter(Mandatory)][string] $Reason,
        [Parameter(Mandatory)][string] $OperationKind
    )

    $timestamp = [DateTime]::UtcNow.ToString('o')
    $Phase.status = 'Blocked'
    $Phase.updatedAt = $timestamp
    $StateData.status = 'Blocked'
    $StateData.authorityRevalidationRequired = $true
    $StateData.nextExactAction = "Resolve routing blocker for phase '$($Phase.phaseId)' and resume explicitly."
    $StateData.lastOperation = [ordered]@{
        kind = $OperationKind
        state = 'Failed'
        summary = $Reason
    }
    $StateData.stop = [ordered]@{
        reason = $Reason
        requestedAt = $timestamp
        safeBoundary = "Before phase '$($Phase.phaseId)' completion"
    }
    $StateData.updatedAt = $timestamp
}

function Write-AMRStatus {
    param(
        [Parameter(Mandatory)][hashtable] $StateData,
        [Parameter(Mandatory)][string] $Format
    )

    $routing = $StateData.routing
    if ($Format -eq 'Json') {
        [ordered]@{
            runId = [string] $StateData.runId
            status = [string] $StateData.status
            policy = [string] $routing.policy
            fallbackPolicy = [string] $routing.fallbackPolicy
            phases = @($routing.phases)
        } | ConvertTo-Json -Depth 20
        return
    }
    Write-Output "Autonomous model routing: $($StateData.runId)"
    Write-Output "Status: $($StateData.status)"
    Write-Output "Policy: $($routing.policy), fallback: $($routing.fallbackPolicy)"
    foreach ($phase in @($routing.phases)) {
        Write-Output "- $($phase.phaseId): $($phase.command), role=$($phase.routingRole), profile=$($phase.runnerProfile), status=$($phase.status)"
    }
}

$statePath = [IO.Path]::GetFullPath($State)
$stateData = Read-AMRJson $statePath
$repositoryRoot = Get-AMRRepositoryRoot $statePath
if ([string]::IsNullOrWhiteSpace($RoutingRoot)) {
    $RoutingRoot = Join-Path $repositoryRoot '.specify/presets'
}
if ([string]::IsNullOrWhiteSpace($Worktree)) {
    $Worktree = $repositoryRoot
}
$Worktree = [IO.Path]::GetFullPath($Worktree)
Assert-AMRCondition (Test-Path -LiteralPath $Worktree -PathType Container) "Worktree fehlt: $Worktree"

$catalog = Get-AMRRoutingCatalog ([IO.Path]::GetFullPath($RoutingRoot))
Assert-AMRPhaseContract $stateData $catalog

if ($Action -eq 'Status') {
    Write-AMRStatus $stateData $OutputFormat
    exit 0
}

Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace($RunnerConfig)) 'RunnerConfig ist fuer Validate und Run erforderlich.'
$runnerData = Read-AMRJson ([IO.Path]::GetFullPath($RunnerConfig))

if ($Action -eq 'Validate') {
    foreach ($phase in @($stateData.routing.phases)) {
        if ([string] $phase.routingRole -ne 'script-only') {
            [void](Get-AMRRunnerProfile $runnerData $phase)
        }
    }
    [ordered]@{
        status = 'VALID'
        policy = [string] $stateData.routing.policy
        fallbackPolicy = [string] $stateData.routing.fallbackPolicy
        phaseCount = @($stateData.routing.phases).Count
    } | ConvertTo-Json
    exit 0
}

Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace($PhaseId)) 'PhaseId ist fuer Run erforderlich.'
Assert-AMRCondition (-not (-not [string]::IsNullOrWhiteSpace($Prompt) -and -not [string]::IsNullOrWhiteSpace($PromptFile))) 'Prompt und PromptFile duerfen nicht gemeinsam gesetzt werden.'
$phase = Get-AMRPhase $stateData $PhaseId
Assert-AMRCondition ([string] $phase.status -in @('Pending', 'Blocked', 'NeedsRevalidation')) "Phase '$PhaseId' ist nicht startbar: $($phase.status)"
foreach ($dependency in @(if ($phase.ContainsKey('dependsOn')) { $phase.dependsOn } else { @() })) {
    $dependencyPhase = @($stateData.routing.phases | Where-Object { [string] $_.phaseId -eq [string] $dependency })[0]
    Assert-AMRCondition ([string] $dependencyPhase.status -eq 'Completed') "Abhaengige Phase '$dependency' ist nicht Completed."
}

$profileResult = Get-AMRRunnerProfile $runnerData $phase
$profileName = [string] $profileResult.name
$runnerProfileData = $profileResult.data

if (-not [string]::IsNullOrWhiteSpace($PromptFile)) {
    Assert-AMRCondition (Test-Path -LiteralPath $PromptFile -PathType Leaf) "PromptFile fehlt: $PromptFile"
    $Prompt = Get-Content -LiteralPath $PromptFile -Raw -Encoding utf8
}
$fullPrompt = "Execute /$($phase.command) for the current repository. Follow the accepted feature artifacts and autonomous run state."
$fullPrompt += "`nWrite the machine-readable phase result to the exact output file from the runner profile. Use autonomous-phase-result-template.json and report Completed only when task and gate evidence is complete."
if (-not [string]::IsNullOrWhiteSpace($Prompt)) {
    $fullPrompt += "`n`nPhase input:`n$Prompt"
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryRoot ".specify/runtime/autonomous-routing/$($stateData.runId)"
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
[void](New-Item -ItemType Directory -Path $OutputDirectory -Force)
$outputFile = Join-Path $OutputDirectory "$PhaseId.result.json"
$logFile = Join-Path $OutputDirectory "$PhaseId.log.txt"
$values = @{
    worktree = $Worktree
    phaseId = $PhaseId
    command = [string] $phase.command
    prompt = $fullPrompt
    outputFile = $outputFile
    logFile = $logFile
    model = [string] $runnerProfileData.model
    reasoningEffort = [string] $runnerProfileData.reasoningEffort
}

if (-not $PSCmdlet.ShouldProcess("phase '$PhaseId'", "Run fail-closed model preflight and phase with profile '$profileName'")) {
    [ordered]@{
        status = 'WHATIF'
        phaseId = $PhaseId
        command = [string] $phase.command
        routingRole = [string] $phase.routingRole
        runnerProfile = $profileName
        agentFamily = [string] $runnerProfileData.agentFamily
        model = [string] $runnerProfileData.model
        reasoningEffort = [string] $runnerProfileData.reasoningEffort
    } | ConvertTo-Json
    exit 0
}

try {
    $preflight = Invoke-AMRCommand $runnerProfileData.preflight $values $Worktree
    if ([int] $preflight.exitCode -ne 0) {
        $reason = "Model preflight failed for profile '$profileName' with exit code $($preflight.exitCode)."
        Set-AMRBlockedState $stateData $phase $reason 'ModelRoutingPreflight'
        $phase.runnerProfile = $profileName
        $phase.agentFamily = [string] $runnerProfileData.agentFamily
        $phase.model = [string] $runnerProfileData.model
        $phase.reasoningEffort = [string] $runnerProfileData.reasoningEffort
        $phase.preflight = 'Failed'
        $phase.exitCode = [int] $preflight.exitCode
        Write-AMRJsonAtomic $statePath $stateData
        throw $reason
    }

    $timestamp = [DateTime]::UtcNow.ToString('o')
    $phase.status = 'Running'
    $phase.runnerProfile = $profileName
    $phase.agentFamily = [string] $runnerProfileData.agentFamily
    $phase.model = [string] $runnerProfileData.model
    $phase.reasoningEffort = [string] $runnerProfileData.reasoningEffort
    $phase.preflight = 'Completed'
    $phase.exitCode = $null
    $phase.updatedAt = $timestamp
    $stateData.status = 'Active'
    $stateData.stop = [ordered]@{ reason = 'N/A'; requestedAt = 'N/A'; safeBoundary = 'N/A' }
    $stateData.lastOperation = [ordered]@{
        kind = "ModelRoutingPhase:$PhaseId"
        state = 'NeedsRevalidation'
        summary = "Phase process started with profile '$profileName'."
    }
    $stateData.updatedAt = $timestamp
    Write-AMRJsonAtomic $statePath $stateData

    $execution = Invoke-AMRCommand $runnerProfileData $values $Worktree
    if ([int] $execution.exitCode -ne 0) {
        $reason = "Phase '$PhaseId' failed with exit code $($execution.exitCode)."
        Set-AMRBlockedState $stateData $phase $reason "ModelRoutingPhase:$PhaseId"
        $phase.exitCode = [int] $execution.exitCode
        Write-AMRJsonAtomic $statePath $stateData
        throw $reason
    }

    if (@($execution.output).Count -gt 0) {
        @($execution.output) | Set-Content -LiteralPath $logFile -Encoding utf8NoBOM
    }
    Assert-AMRCondition (Test-Path -LiteralPath $outputFile -PathType Leaf) "Phase '$PhaseId' produced no structured result."
    $validationOutput = @(& (Join-Path $PSScriptRoot 'validate-autonomous-phase-result.ps1') `
        -Repo $repositoryRoot -Result $outputFile -PhaseId $PhaseId -ExitCode ([int] $execution.exitCode) 2>&1)
    $validationExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    if ($validationExitCode -ne 0) {
        $reason = "Phase '$PhaseId' semantic result validation failed: $($validationOutput -join ' ')"
        Set-AMRBlockedState $stateData $phase $reason "ModelRoutingPhase:$PhaseId"
        $phase.exitCode = 0
        Write-AMRJsonAtomic $statePath $stateData
        throw $reason
    }
    $validation = ($validationOutput -join "`n") | ConvertFrom-Json
    $resultHash = [string] $validation.normalizedSha256
    $timestamp = [DateTime]::UtcNow.ToString('o')
    $phase.status = 'Completed'
    $phase.exitCode = 0
    $phase.resultPath = [IO.Path]::GetRelativePath($repositoryRoot, $outputFile).Replace('\\', '/')
    $phase.resultSha256 = $resultHash
    $phase.updatedAt = $timestamp
    $nextPhase = @($stateData.routing.phases | Where-Object { [string] $_.status -in @('Pending', 'NeedsRevalidation') }) | Select-Object -First 1
    $stateData.nextExactAction = if ($null -eq $nextPhase) { 'Continue autonomous validation and closeout.' } else { "Run routing phase '$($nextPhase.phaseId)'." }
    $stateData.lastOperation = [ordered]@{
        kind = "ModelRoutingPhase:$PhaseId"
        state = 'Completed'
        summary = "Phase completed with profile '$profileName' and result SHA-256 $resultHash."
    }
    $stateData.updatedAt = $timestamp
    Write-AMRJsonAtomic $statePath $stateData

    [ordered]@{
        status = 'COMPLETED'
        phaseId = $PhaseId
        command = [string] $phase.command
        routingRole = [string] $phase.routingRole
        runnerProfile = $profileName
        agentFamily = [string] $runnerProfileData.agentFamily
        model = [string] $runnerProfileData.model
        reasoningEffort = [string] $runnerProfileData.reasoningEffort
        resultPath = [string] $phase.resultPath
        resultSha256 = $resultHash
    } | ConvertTo-Json
} catch {
    if ([string] $phase.status -ne 'Blocked') {
        Set-AMRBlockedState $stateData $phase $_.Exception.Message "ModelRoutingPhase:$PhaseId"
        Write-AMRJsonAtomic $statePath $stateData
    }
    throw
}
