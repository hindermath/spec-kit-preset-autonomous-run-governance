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
    if ($script:TrustedStatePath -and [string]::Equals([IO.Path]::GetFullPath($Path),
            $script:TrustedStatePath, [StringComparison]::Ordinal)) {
        # A worker may replace the feature directory after its process exits.
        # Never create a missing State parent or follow a redirected one.
        $currentParent = Resolve-AMRPhysicalProgramPath $parent $parent
        $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
        Assert-AMRCondition ([string]::Equals($currentParent, $script:TrustedStateParent, $comparison)) `
            "State-Elternverzeichnis wurde nach dem Start umgeleitet: $parent"
        $stateEntry = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        Assert-AMRCondition ($null -eq $stateEntry -or
            ($stateEntry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) `
            "State-Datei darf kein Symlink oder Reparse Point sein: $Path"
        $python = Get-Command python3 -ErrorAction SilentlyContinue
        if ($null -eq $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
        Assert-AMRCondition ($null -ne $python) 'Python fehlt fuer den verankerten State-Schreibzugriff.'
        $relativeState = [IO.Path]::GetRelativePath($repositoryRoot, $Path).Replace('\', '/')
        $json = ($Value | ConvertTo-Json -Depth 30) + [Environment]::NewLine
        $json | & $python.Source (Join-Path $PSScriptRoot 'autonomous-evidence-core.py') state-write `
            --repo-root $script:TrustedRepositoryRoot --relative-state $relativeState
        Assert-AMRCondition ($LASTEXITCODE -eq 0) "State konnte nicht sicher geschrieben werden: $Path"
        return
    } elseif ($parent) {
        [void](New-Item -ItemType Directory -Path $parent -Force)
    }
    $temporaryPath = "${Path}.tmp.$([guid]::NewGuid().ToString('N'))"
    try {
        $json = ($Value | ConvertTo-Json -Depth 30) + [Environment]::NewLine
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
        $stream = [IO.FileStream]::new($temporaryPath, [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        } finally {
            $stream.Dispose()
        }
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

function Assert-AMROutputDirectoryBoundary {
    param(
        [Parameter(Mandatory)][string] $Repository,
        [Parameter(Mandatory)][string] $Output
    )

    $root = [IO.Path]::GetFullPath($Repository)
    $full = [IO.Path]::GetFullPath($Output)
    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $prefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, $comparison)) {
        # An explicit external output directory is an operator-selected location.
        $entry = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
        Assert-AMRCondition ($null -eq $entry -or
            ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) `
            "OutputDirectory ist ein Symlink oder Reparse Point: $full"
        return
    }
    $current = $root
    foreach ($segment in $full.Substring($prefix.Length).Split([char[]]@('/', '\'), [StringSplitOptions]::RemoveEmptyEntries)) {
        $current = Join-Path $current $segment
        $entry = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        Assert-AMRCondition ($null -eq $entry -or
            ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) `
            "OutputDirectory enthaelt Symlink oder Reparse Point: $current"
    }
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
        Assert-AMRCondition ($currentId -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') "Routing phaseId ist kein sicherer Dateiname: $currentId"
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
        if ([string] $phase.routingRole -ne 'script-only') {
            Assert-AMRCondition (($phase.expectedTasks -is [int] -or $phase.expectedTasks -is [long]) -and
                [long] $phase.expectedTasks -gt 0) "Akzeptierte positive Aufgabenzahl fehlt: $($phase.phaseId)"
            Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $phase.expectedPayloadPath) -and
                -not [IO.Path]::IsPathRooted([string] $phase.expectedPayloadPath) -and
                [string] $phase.expectedPayloadPath -notmatch '(^|[/\\])\.\.([/\\]|$)') "Akzeptierter repository-relativer Payload-Pfad fehlt: $($phase.phaseId)"
        }
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
    Assert-AMRCondition ($runnerProfileData.postflight -is [hashtable]) "postflight fehlt fuer unabhaengige Phasen-Gates: $profileName"
    Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $runnerProfileData.postflight.executable)) "postflight.executable fehlt: $profileName"
    Assert-AMRCondition ($runnerProfileData.postflight.arguments -is [object[]]) "postflight.arguments muss ein Array sein: $profileName"
    Assert-AMRCondition ($null -ne (Get-Command ([string] $runnerProfileData.executable) -ErrorAction SilentlyContinue)) "Runner executable nicht gefunden: $($runnerProfileData.executable)"
    Assert-AMRCondition ($null -ne (Get-Command ([string] $runnerProfileData.preflight.executable) -ErrorAction SilentlyContinue)) "Preflight executable nicht gefunden: $($runnerProfileData.preflight.executable)"
    Assert-AMRCondition ($null -ne (Get-Command ([string] $runnerProfileData.postflight.executable) -ErrorAction SilentlyContinue)) "Postflight executable nicht gefunden: $($runnerProfileData.postflight.executable)"

    return [ordered]@{
        name = $profileName
        data = $runnerProfileData
    }
}

function Resolve-AMRPhysicalProgramPath {
    param([string] $Path, [string] $Base, [int] $Depth = 0)
    Assert-AMRCondition ($Depth -lt 16) 'Postflight-Programmpfad hat zu viele Symlinks.'
    $full = [IO.Path]::GetFullPath($Path, $Base)
    $root = [IO.Path]::GetPathRoot($full)
    $current = $root
    foreach ($part in $full.Substring($root.Length).Split([char[]]@('/', '\'), [StringSplitOptions]::RemoveEmptyEntries)) {
        $current = Join-Path $current $part
        $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            $target = $item.ResolveLinkTarget($true)
            Assert-AMRCondition ($null -ne $target) "Postflight-Programm hat unaufloesbaren Symlink: $current"
            $current = Resolve-AMRPhysicalProgramPath $target.FullName $Base ($Depth + 1)
        }
    }
    return [IO.Path]::GetFullPath($current)
}

function Assert-AMRPostflightBoundary {
    param([hashtable] $Postflight, [string] $Worktree)
    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $workerPrefix = (Resolve-AMRPhysicalProgramPath $Worktree $Worktree).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $executable = (Get-Command ([string] $Postflight.executable) -ErrorAction Stop).Source
    $arguments = @($Postflight.arguments | ForEach-Object { [string] $_ })
    $interpreter = [IO.Path]::GetFileNameWithoutExtension($executable).ToLowerInvariant()
    $scriptIndex = -1
    if ($interpreter -in @('pwsh', 'powershell')) {
        $index = 0
        while ($index -lt $arguments.Count -and $arguments[$index] -in @('-NoProfile', '-NoLogo', '-NonInteractive')) {
            $index++
        }
        Assert-AMRCondition ($index + 1 -lt $arguments.Count -and $arguments[$index] -ceq '-File' -and
            $arguments[$index + 1] -match '\.ps1$') 'Postflight-PowerShell muss ein festes Skript mit -File ausfuehren.'
        $scriptIndex = $index + 1
    } elseif ($interpreter -in @('bash', 'sh', 'python', 'python3', 'node')) {
        $extension = if ($interpreter -in @('bash', 'sh')) { 'sh' } elseif ($interpreter -eq 'node') { 'js' } else { 'py' }
        Assert-AMRCondition ($arguments.Count -gt 0 -and $arguments[0] -match "\.$extension`$") `
            'Postflight-Interpreter muss als erstes Argument ein festes Skript ausfuehren.'
        $scriptIndex = 0
    } else {
        Assert-AMRCondition ($interpreter -notin @('env', 'xargs')) 'Postflight darf keinen allgemeinen Programm-Wrapper verwenden.'
    }
    $candidates = @($executable)
    if ($scriptIndex -ge 0) {
        Assert-AMRCondition ($arguments[$scriptIndex] -notmatch '\{[^}]+\}') 'Postflight-Programm darf keine Pfad-Platzhalter verwenden.'
        $candidates += $arguments[$scriptIndex]
    }
    foreach ($candidate in $candidates) {
        $path = Resolve-AMRPhysicalProgramPath ([string] $candidate) $Worktree
        Assert-AMRCondition (-not $path.StartsWith($workerPrefix, $comparison)) `
            "Postflight-Programm liegt im beschreibbaren Worker-Worktree: $path"
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

function Write-AMRNativeReadOnlyResult {
    param([Parameter(Mandatory)][object[]]$Output,[Parameter(Mandatory)][string]$Path)
    $text=($Output|ForEach-Object{[string]$_}) -join "`n"
    $value=$text|ConvertFrom-Json -AsHashtable -Depth 100
    Assert-AMRCondition ($value -is [Collections.IDictionary]) 'Native read-only result must be one JSON object.'
    Write-AMRJsonAtomic -Path $Path -Value $value
}

function Invoke-AMRCommand {
    param(
        [Parameter(Mandatory)][hashtable] $CommandProfile,
        [Parameter(Mandatory)][hashtable] $Values,
        [Parameter(Mandatory)][string] $WorkingDirectory
    )

    $arguments = if (Get-Command Expand-MRExecutionArguments -ErrorAction SilentlyContinue) {
        Expand-MRExecutionArguments -ExecutionProfile $CommandProfile -Values $Values
    } else { ConvertTo-AMRArguments @($CommandProfile.arguments) $Values }
    $previousPwd = [Environment]::GetEnvironmentVariable('PWD')
    Push-Location -LiteralPath $WorkingDirectory
    try {
        $env:PWD = $WorkingDirectory
        $output = @(& ([string] $CommandProfile.executable) @arguments 2>&1)
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    } finally {
        [Environment]::SetEnvironmentVariable('PWD',$previousPwd)
        Pop-Location
    }
    if($exitCode -eq 0 -and $CommandProfile.ContainsKey('agentFamily') -and
        [string]$CommandProfile.agentFamily -ceq 'Antigravity' -and [string]$CommandProfile.routingRole -ceq 'fast-mechanical'){
        # The host owns result persistence; a read-only model must never need
        # write_file permission merely to hand its structured phase result back.
        Write-AMRNativeReadOnlyResult -Output $output -Path ([string]$Values.outputFile)
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
$repositoryRoot = Get-AMRRepositoryRoot $statePath
$script:TrustedRepositoryRoot = Resolve-AMRPhysicalProgramPath $repositoryRoot $repositoryRoot
$script:TrustedStateParent = Resolve-AMRPhysicalProgramPath (Split-Path -Parent $statePath) (Split-Path -Parent $statePath)
$stateComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
$statePrefix = $script:TrustedRepositoryRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
Assert-AMRCondition ($script:TrustedStateParent.StartsWith($statePrefix, $stateComparison)) `
    'State-Elternverzeichnis muss physisch im Repository liegen.'
$stateEntry = Get-Item -LiteralPath $statePath -Force -ErrorAction Stop
Assert-AMRCondition (($stateEntry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) `
    'State-Datei darf kein Symlink oder Reparse Point sein.'
$stateData = Read-AMRJson $statePath
$script:TrustedStatePath = $statePath
$parsedRunId = [guid]::Empty
Assert-AMRCondition ([guid]::TryParse([string]$stateData.runId, [ref]$parsedRunId) -and
    $parsedRunId -ne [guid]::Empty) 'State.runId muss eine nichtleere UUID sein.'
if ([string]::IsNullOrWhiteSpace($RoutingRoot)) {
    $RoutingRoot = Join-Path $repositoryRoot '.specify/presets'
}
if ([string]::IsNullOrWhiteSpace($Worktree)) {
    $Worktree = $repositoryRoot
}
$Worktree = [IO.Path]::GetFullPath($Worktree)
Assert-AMRCondition (Test-Path -LiteralPath $Worktree -PathType Container) "Worktree fehlt: $Worktree"

$executionPolicy = Join-Path $RoutingRoot 'model-routing-governance/scripts/execution-policy.psm1'
if (Test-Path -LiteralPath $executionPolicy -PathType Leaf) {
    Import-Module $executionPolicy -Force
    $Worktree = Resolve-MRExecutionPath $Worktree
}

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
            $checkedProfile = Get-AMRRunnerProfile $runnerData $phase
            Assert-AMRPostflightBoundary $checkedProfile.data.postflight $Worktree
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
$expectedTasks = [int] $phase.expectedTasks
if ([string] $phase.command -eq 'speckit.implement') {
    $expectedTasks = [int] $stateData.tasks.total
    Assert-AMRCondition ($expectedTasks -gt 0 -and -not [string]::IsNullOrWhiteSpace([string] $stateData.tasks.path) -and
        [string] $stateData.tasks.path -ne 'N/A') 'Implementierung benoetigt ein akzeptiertes tasks.md mit positiver Aufgabenzahl.'
}
Assert-AMRCondition ($expectedTasks -gt 0) "Akzeptierte Aufgabenzahl muss positiv sein: $PhaseId"
Assert-AMRCondition (-not [string]::IsNullOrWhiteSpace([string] $phase.expectedPayloadPath)) "Akzeptierter Payload-Pfad fehlt: $PhaseId"
foreach ($dependency in @(if ($phase.ContainsKey('dependsOn')) { $phase.dependsOn } else { @() })) {
    $dependencyPhase = @($stateData.routing.phases | Where-Object { [string] $_.phaseId -eq [string] $dependency })[0]
    Assert-AMRCondition ([string] $dependencyPhase.status -eq 'Completed') "Abhaengige Phase '$dependency' ist nicht Completed."
}

$profileResult = Get-AMRRunnerProfile $runnerData $phase
$profileName = [string] $profileResult.name
$runnerProfileData = $profileResult.data
Assert-AMRPostflightBoundary $runnerProfileData.postflight $Worktree

if (-not [string]::IsNullOrWhiteSpace($PromptFile)) {
    Assert-AMRCondition (Test-Path -LiteralPath $PromptFile -PathType Leaf) "PromptFile fehlt: $PromptFile"
    $Prompt = Get-Content -LiteralPath $PromptFile -Raw -Encoding utf8
}
$fullPrompt = "Execute /$($phase.command) for the current repository. Follow the accepted feature artifacts and autonomous run state."
$fullPrompt += "`nUse autonomous-phase-result-template.json and report Completed only when task and gate evidence is complete."
if (-not [string]::IsNullOrWhiteSpace($Prompt)) {
    $fullPrompt += "`n`nPhase input:`n$Prompt"
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repositoryRoot ".specify/runtime/autonomous-routing/$($stateData.runId)"
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$attemptId = [guid]::NewGuid().ToString()
$outputFile = Join-Path $OutputDirectory "$PhaseId.$attemptId.result.json"
$logFile = Join-Path $OutputDirectory "$PhaseId.$attemptId.log.txt"
$expectedPayload = ([string] $phase.expectedPayloadPath).Replace('{runId}', [string] $stateData.runId).Replace('{phaseId}', $PhaseId).Replace('{attemptId}', $attemptId)
Assert-AMRCondition (-not [IO.Path]::IsPathRooted($expectedPayload) -and $expectedPayload -notmatch '(^|[/\\])\.\.([/\\]|$)') "Akzeptierter Payload-Pfad ist nicht repository-relativ: $PhaseId"
$taskManifest = if ([string] $phase.command -eq 'speckit.implement') { [string] $stateData.tasks.path } else { '' }
$taskInventorySha = ''
if ($taskManifest) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
    if ($null -eq $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
    Assert-AMRCondition ($null -ne $python) 'Python fehlt fuer den Task-Manifest-Vertrag.'
    $contractOutput = @(& $python.Source (Join-Path $PSScriptRoot 'autonomous-evidence-core.py') task-contract `
        --repo $Worktree --task-manifest $taskManifest --expected-tasks $expectedTasks `
        --accepted-hash ([string] $stateData.tasks.sha256) 2>&1)
    Assert-AMRCondition ($LASTEXITCODE -eq 0) "Akzeptiertes Task-Manifest ist ungueltig: $($contractOutput -join ' ')"
    $taskInventorySha = [string] (($contractOutput -join "`n" | ConvertFrom-Json).taskInventorySha256)
}
$fullPrompt += "`nUse this exact attemptId in the phase-result JSON: $attemptId"
if ('-HarnessArgumentsJson' -cin @($runnerProfileData.arguments) -or
    ([string]$runnerProfileData.agentFamily -ceq 'Antigravity' -and [string]$runnerProfileData.routingRole -ceq 'fast-mechanical')) {
    $fullPrompt += "`nReturn the phase-result JSON object on standard output; the configured result adapter owns writing the runner result file."
} else {
    $fullPrompt += "`nWrite the machine-readable phase-result JSON object to this exact runner-owned path: $outputFile"
}
$values = @{
    worktree = $Worktree
    statePath = $statePath
    coordinatorPid = $PID
    phaseId = $PhaseId
    attemptId = $attemptId
    command = [string] $phase.command
    prompt = $fullPrompt
    outputFile = $outputFile
    logFile = $logFile
    payloadPath = Join-Path $Worktree $expectedPayload
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

Assert-AMROutputDirectoryBoundary $repositoryRoot $OutputDirectory
[void](New-Item -ItemType Directory -Path $OutputDirectory -Force)
Assert-AMROutputDirectoryBoundary $repositoryRoot $OutputDirectory
$outputDirectoryEntry = Get-Item -LiteralPath $OutputDirectory -Force
Assert-AMRCondition (($outputDirectoryEntry.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) `
    "OutputDirectory ist ein Symlink oder Reparse Point: $OutputDirectory"
# Open before either untrusted preflight or runner can replace the pathname.
$logStream = [IO.FileStream]::new($logFile, [IO.FileMode]::CreateNew,
    [IO.FileAccess]::Write, [IO.FileShare]::None)

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
    $phase.attemptId = $attemptId
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

    # Hold the original inode while the runner sees the log path. A runner can
    # unlink the name, but it cannot redirect our write through a replacement link.
    try {
        $execution = Invoke-AMRCommand $runnerProfileData $values $Worktree
        if (@($execution.output).Count -gt 0) {
            $logText = (@($execution.output) -join [Environment]::NewLine) + [Environment]::NewLine
            $logBytes = [Text.UTF8Encoding]::new($false).GetBytes($logText)
            $logStream.Write($logBytes, 0, $logBytes.Length)
        }
        $logStream.Flush($true)
    } finally {
        $logStream.Dispose()
    }
    if ([int] $execution.exitCode -ne 0) {
        $reason = "Phase '$PhaseId' failed with exit code $($execution.exitCode)."
        Set-AMRBlockedState $stateData $phase $reason "ModelRoutingPhase:$PhaseId"
        $phase.exitCode = [int] $execution.exitCode
        Write-AMRJsonAtomic $statePath $stateData
        throw $reason
    }

    Assert-AMRCondition (Test-Path -LiteralPath $outputFile -PathType Leaf) "Phase '$PhaseId' produced no structured result."
    # The locally configured postflight runs after the model and supplies the
    # gate decision; the model's gatesSatisfied flag cannot grant completion.
    $gate = Invoke-AMRCommand $runnerProfileData.postflight $values $Worktree
    $validationOutput = @(& (Join-Path $PSScriptRoot 'validate-autonomous-phase-result.ps1') `
        -Repo $Worktree -Result $outputFile -PhaseId $PhaseId -AttemptId $attemptId -ExitCode ([int] $execution.exitCode) `
        -ExpectedTasks $expectedTasks -ExpectedPayload $expectedPayload -GateExitCode ([int] $gate.exitCode) `
        -TaskManifest $taskManifest -TaskInventorySha $taskInventorySha 2>&1)
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
} finally {
    $logStream.Dispose()
}
