#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-RoutingTest {
    param(
        [Parameter(Mandatory)][bool] $Condition,
        [Parameter(Mandatory)][string] $Message
    )
    if (-not $Condition) { throw $Message }
}

function Write-RoutingJson {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)] $Value
    )
    $parent = Split-Path -Parent $Path
    [void](New-Item -ItemType Directory -Path $parent -Force)
    $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

$presetRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $presetRoot 'scripts/invoke-autonomous-model-phase.ps1'
$fixtureRunner = Join-Path $PSScriptRoot 'fixture-model-runner.ps1'
$allPresetRoot = Split-Path -Parent $presetRoot
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) "autonomous-model-routing-$([guid]::NewGuid())"
$repository = Join-Path $temporaryRoot 'repository'
$featureDirectory = Join-Path $repository 'specs/999-routing-fixture'
$statePath = Join-Path $featureDirectory 'autonomous-run-state.json'
$runnerConfig = Join-Path $temporaryRoot 'runner-profiles.json'

try {
    [void](New-Item -ItemType Directory -Path $featureDirectory -Force)
    & git -C $repository init --quiet

    $state = [ordered]@{
        schemaVersion = '1.1'
        runId = [guid]::NewGuid().ToString()
        featurePath = 'specs/999-routing-fixture'
        branch = '999-routing-fixture'
        deliveryMode = 'LocalImplementation'
        authorityRevalidationRequired = $true
        stage = 'Plan'
        status = 'Active'
        checkpointCommit = 'N/A'
        acceptedArtifacts = @()
        tasks = [ordered]@{ path = 'N/A'; sha256 = 'N/A'; completed = 0; total = 0 }
        routing = [ordered]@{
            policy = 'balanced-v1'
            fallbackPolicy = 'fail-closed'
            phases = @(
                [ordered]@{
                    phaseId = 'read-intake'
                    command = 'speckit.intake-read'
                    routingRole = 'fast-mechanical'
                    runnerProfile = 'N/A'
                    dependsOn = @()
                    status = 'Pending'
                },
                [ordered]@{
                    phaseId = 'plan'
                    command = 'speckit.plan'
                    routingRole = 'frontier-reasoning'
                    runnerProfile = 'N/A'
                    dependsOn = @('read-intake')
                    status = 'Pending'
                }
            )
        }
        lastPassingGate = 'Preflight'
        nextExactAction = "Run routing phase 'read-intake'."
        lastOperation = [ordered]@{ kind = 'N/A'; state = 'N/A'; summary = 'No operation has started.' }
        stop = [ordered]@{ reason = 'N/A'; requestedAt = 'N/A'; safeBoundary = 'N/A' }
        closeout = [ordered]@{
            mergeOrPublication = 'N/A'
            defaultBranchSync = 'N/A'
            postMergeActions = 'N/A'
            finalValidation = 'Pending'
        }
        updatedAt = [DateTime]::UtcNow.ToString('o')
    }
    Write-RoutingJson $statePath $state

    $fixtureArguments = @(
        '-NoProfile', '-File', $fixtureRunner,
        '-OutputFile', '{outputFile}', '-Content', '{command}'
    )
    $profiles = [ordered]@{
        schemaVersion = '1.0'
        profiles = [ordered]@{
            'fixture-fast' = [ordered]@{
                routingRole = 'fast-mechanical'
                agentFamily = 'Fixture Agent'
                model = 'fixture-fast-model'
                reasoningEffort = 'low'
                executable = 'pwsh'
                preflight = [ordered]@{
                    executable = 'pwsh'
                    arguments = @('-NoProfile', '-File', $fixtureRunner)
                }
                arguments = $fixtureArguments
            }
            'fixture-frontier' = [ordered]@{
                routingRole = 'frontier-reasoning'
                agentFamily = 'Fixture Agent'
                model = 'fixture-frontier-model'
                reasoningEffort = 'high'
                executable = 'pwsh'
                preflight = [ordered]@{
                    executable = 'pwsh'
                    arguments = @('-NoProfile', '-File', $fixtureRunner)
                }
                arguments = $fixtureArguments
            }
        }
    }
    Write-RoutingJson $runnerConfig $profiles

    $validation = @(& pwsh -NoProfile -File $runner -Action Validate -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot 2>&1)
    Assert-RoutingTest ($LASTEXITCODE -eq 0) "Valid routing fixture failed: $($validation -join [Environment]::NewLine)"

    $first = @(& pwsh -NoProfile -File $runner -Action Run -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot -PhaseId 'read-intake' 2>&1)
    Assert-RoutingTest ($LASTEXITCODE -eq 0) "Fast phase failed: $($first -join [Environment]::NewLine)"
    $afterFirst = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    Assert-RoutingTest ($afterFirst.routing.phases[0].status -eq 'Completed') 'Fast phase did not complete'
    Assert-RoutingTest ($afterFirst.routing.phases[0].model -eq 'fixture-fast-model') 'Fast model metadata missing'
    Assert-RoutingTest ($afterFirst.routing.phases[1].status -eq 'Pending') 'Dependent phase changed prematurely'

    $second = @(& pwsh -NoProfile -File $runner -Action Run -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot -PhaseId 'plan' 2>&1)
    Assert-RoutingTest ($LASTEXITCODE -eq 0) "Frontier phase failed: $($second -join [Environment]::NewLine)"
    $afterSecond = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    Assert-RoutingTest ($afterSecond.routing.phases[1].status -eq 'Completed') 'Frontier phase did not complete'
    Assert-RoutingTest ($afterSecond.routing.phases[1].model -eq 'fixture-frontier-model') 'Frontier model metadata missing'
    Assert-RoutingTest ($afterSecond.routing.phases[1].resultSha256 -match '^[0-9a-f]{64}$') 'Result hash missing'

    $invalidStatePath = Join-Path $featureDirectory 'invalid-role-state.json'
    $invalidState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
    $invalidState.routing.phases[1].routingRole = 'fast-mechanical'
    $invalidState.routing.phases[1].status = 'Pending'
    $invalidState.routing.phases[1].runnerProfile = 'N/A'
    Write-RoutingJson $invalidStatePath $invalidState
    & pwsh -NoProfile -File $runner -Action Validate -State $invalidStatePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Role drift was accepted'

    $scriptOnlyStatePath = Join-Path $featureDirectory 'script-only-state.json'
    $scriptOnlyState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
    $scriptOnlyState.routing.phases = @(
        [ordered]@{
            phaseId = 'stop'
            command = 'speckit.autonomous-stop'
            routingRole = 'script-only'
            runnerProfile = 'N/A'
            dependsOn = @()
            status = 'Pending'
        }
    )
    Write-RoutingJson $scriptOnlyStatePath $scriptOnlyState
    & pwsh -NoProfile -File $runner -Action Run -State $scriptOnlyStatePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot -PhaseId 'stop' *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'script-only command was started through a model runner'

    $routingFiles = @(Get-ChildItem -LiteralPath $allPresetRoot -Filter 'model-routing.json' -File -Recurse)
    Assert-RoutingTest ($routingFiles.Count -eq 12) 'The active managed profile must provide exactly twelve routing files'
    $roleRank = @{
        'script-only' = 0
        'fast-mechanical' = 10
        'long-running-implementation' = 20
        'coding-review' = 30
        'frontier-reasoning' = 40
    }
    $effectiveRoles = @{}
    foreach ($routingFile in $routingFiles) {
        $routingText = Get-Content -LiteralPath $routingFile.FullName -Raw
        Assert-RoutingTest ($routingText -notmatch '(?i)gpt-|claude-|gemini-') "Provider model leaked into $($routingFile.FullName)"
        $routingData = $routingText | ConvertFrom-Json -AsHashtable
        $manifestPath = Join-Path $routingFile.DirectoryName 'preset.yml'
        $manifestText = Get-Content -LiteralPath $manifestPath -Raw
        $registeredCommands = [regex]::Matches(
            $manifestText,
            '(?m)^\s+name:\s+"(speckit\.[^"]+)"\s*$'
        )
        foreach ($registeredCommand in $registeredCommands) {
            $commandName = [string] $registeredCommand.Groups[1].Value
            Assert-RoutingTest $routingData.commands.ContainsKey($commandName) "Missing routing for $commandName in $manifestPath"
        }
        foreach ($routingEntry in $routingData.commands.GetEnumerator()) {
            $commandName = [string] $routingEntry.Key
            $roleName = [string] $routingEntry.Value
            if (-not $effectiveRoles.ContainsKey($commandName) -or
                $roleRank[$roleName] -gt $roleRank[[string] $effectiveRoles[$commandName]]) {
                $effectiveRoles[$commandName] = $roleName
            }
        }
    }

    $expectedBalancedRoles = @{
        'speckit.specify' = 'frontier-reasoning'
        'speckit.clarify' = 'frontier-reasoning'
        'speckit.checklist' = 'frontier-reasoning'
        'speckit.plan' = 'frontier-reasoning'
        'speckit.tasks' = 'frontier-reasoning'
        'speckit.analyze' = 'frontier-reasoning'
        'speckit.implement' = 'long-running-implementation'
        'speckit.intake-read' = 'fast-mechanical'
        'speckit.intake-series-next' = 'fast-mechanical'
        'speckit.autonomous-retrospective' = 'coding-review'
        'speckit.parallel-autonomous-consolidate' = 'coding-review'
        'speckit.autonomous-stop' = 'script-only'
        'speckit.parallel-autonomous-stop' = 'script-only'
    }
    foreach ($expectedRole in $expectedBalancedRoles.GetEnumerator()) {
        Assert-RoutingTest $effectiveRoles.ContainsKey([string] $expectedRole.Key) "Missing balanced command $($expectedRole.Key)"
        Assert-RoutingTest (
            [string] $effectiveRoles[[string] $expectedRole.Key] -eq [string] $expectedRole.Value
        ) "Unexpected effective role for $($expectedRole.Key)"
    }

    Write-Output 'PASS: balanced command routing, phase switching, fail-closed validation, and script-only separation'
} finally {
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
}
