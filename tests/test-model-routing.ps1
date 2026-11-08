#Requires -Version 7.0
[CmdletBinding()]
param([string] $ModelRoutingSource = '')

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
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) "autonomous-model-routing-$([guid]::NewGuid())"
$allPresetRoot = Join-Path $temporaryRoot 'routing-presets'
$repository = Join-Path $temporaryRoot 'repository'
$featureDirectory = Join-Path $repository 'specs/999-routing-fixture'
$statePath = Join-Path $featureDirectory 'autonomous-run-state.json'
$runnerConfig = Join-Path $temporaryRoot 'runner-profiles.json'

try {
    if ($ModelRoutingSource) {
        $executionDirectory = Join-Path $allPresetRoot 'model-routing-governance/scripts'
        [void](New-Item -ItemType Directory -Path $executionDirectory -Force)
        Copy-Item (Join-Path $ModelRoutingSource 'scripts/execution-policy.psm1') $executionDirectory
    }
    # Test the shipped contract without depending on unrelated sibling checkouts.
    # A weaker plan binding also proves that composition retains the strongest role.
    $autonomousCatalogRoot = Join-Path $allPresetRoot 'autonomous-run-governance'
    [void](New-Item -ItemType Directory -Path $autonomousCatalogRoot -Force)
    Copy-Item -LiteralPath (Join-Path $presetRoot 'model-routing.json'),
        (Join-Path $presetRoot 'preset.yml') -Destination $autonomousCatalogRoot
    $compositionRoot = Join-Path $allPresetRoot 'fixture-composition'
    $compositionCatalogPath = Join-Path $compositionRoot 'model-routing.json'
    $compositionCatalog = [ordered]@{
        schemaVersion = '1.0'
        presetId = 'fixture-composition'
        fallbackPolicy = 'fail-closed'
        defaultRole = 'frontier-reasoning'
        commands = [ordered]@{
            'speckit.plan' = 'fast-mechanical'
            'speckit.intake-read' = 'fast-mechanical'
            'speckit.intake-series-next' = 'fast-mechanical'
            'speckit.parallel-autonomous-consolidate' = 'coding-review'
            'speckit.parallel-autonomous-stop' = 'script-only'
        }
    }
    Write-RoutingJson $compositionCatalogPath $compositionCatalog
    'contributions: []' | Set-Content -LiteralPath (Join-Path $compositionRoot 'preset.yml') -Encoding utf8NoBOM
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
                    expectedTasks = 1
                    expectedPayloadPath = '.specify/runtime/autonomous-routing/{runId}/{phaseId}.{attemptId}.result.payload.txt'
                    dependsOn = @()
                    status = 'Pending'
                },
                [ordered]@{
                    phaseId = 'plan'
                    command = 'speckit.plan'
                    routingRole = 'frontier-reasoning'
                    runnerProfile = 'N/A'
                    expectedTasks = 1
                    expectedPayloadPath = '.specify/runtime/autonomous-routing/{runId}/{phaseId}.{attemptId}.result.payload.txt'
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

    $outsideLog = Join-Path $temporaryRoot 'outside-log.txt'
    'unchanged outside log' | Set-Content -LiteralPath $outsideLog -Encoding utf8NoBOM
    $outsideLogHash = (Get-FileHash -LiteralPath $outsideLog -Algorithm SHA256).Hash
    $outsideState = Join-Path $temporaryRoot 'outside-state.txt'
    'unchanged outside state' | Set-Content -LiteralPath $outsideState -Encoding utf8NoBOM
    $outsideStateHash = (Get-FileHash -LiteralPath $outsideState -Algorithm SHA256).Hash
    $fixtureArguments = @(
        '-NoProfile', '-File', $fixtureRunner,
        '-OutputFile', '{outputFile}', '-PhaseId', '{phaseId}', '-AttemptId', '{attemptId}', '-Content', '{command}',
        '-LogFile', '{logFile}', '-LogSymlinkTarget', $outsideLog,
        '-StatePath', '{statePath}', '-StateTempSymlinkTarget', $outsideState,
        '-CoordinatorPid', '{coordinatorPid}'
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
                postflight = [ordered]@{
                    executable = 'pwsh'
                    arguments = @('-NoProfile', '-File', $fixtureRunner, '-CheckPayload', '{payloadPath}', '-Content', '{command}')
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
                postflight = [ordered]@{
                    executable = 'pwsh'
                    arguments = @('-NoProfile', '-File', $fixtureRunner, '-CheckPayload', '{payloadPath}', '-Content', '{command}')
                }
                arguments = $fixtureArguments
            }
        }
    }
    Write-RoutingJson $runnerConfig $profiles

    $previewDirectory = Join-Path $temporaryRoot 'preview-only'
    $previewStateHash = (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash
    & pwsh -NoProfile -File $runner -Action Run -State $statePath -RunnerConfig $runnerConfig `
        -RoutingRoot $allPresetRoot -PhaseId 'read-intake' -OutputDirectory $previewDirectory -WhatIf *> $null
    Assert-RoutingTest ($LASTEXITCODE -eq 0) 'Routing WhatIf preview failed'
    Assert-RoutingTest (-not (Test-Path -LiteralPath $previewDirectory)) 'Routing WhatIf created output directory'
    Assert-RoutingTest ((Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash -ceq $previewStateHash) `
        'Routing WhatIf changed run state'

    $validation = @(& pwsh -NoProfile -File $runner -Action Validate -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot 2>&1)
    Assert-RoutingTest ($LASTEXITCODE -eq 0) "Valid routing fixture failed: $($validation -join [Environment]::NewLine)"
    $workerGate = Join-Path $repository 'worker-gate.ps1'
    'exit 0' | Set-Content -LiteralPath $workerGate -Encoding utf8NoBOM
    $profiles.profiles['fixture-fast'].postflight.arguments = @('-NoProfile', '-File', $workerGate)
    Write-RoutingJson $runnerConfig $profiles
    $badGateValidation = @(& pwsh -NoProfile -File $runner -Action Validate -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot 2>&1)
    Assert-RoutingTest ($LASTEXITCODE -ne 0) "Worker-writable postflight gate was accepted: $($badGateValidation -join ' ')"
    $profiles.profiles['fixture-fast'].postflight.arguments = @('-NoProfile', '-File', '{worktree}/worker-gate.ps1')
    Write-RoutingJson $runnerConfig $profiles
    & pwsh -NoProfile -File $runner -Action Validate -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Placeholder postflight gate was accepted'
    $profiles.profiles['fixture-fast'].postflight.arguments = @('-NoProfile', '-com', 'Write-Output BYPASS', $fixtureRunner)
    Write-RoutingJson $runnerConfig $profiles
    & pwsh -NoProfile -File $runner -Action Validate -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'PowerShell abbreviated dynamic command bypassed postflight gate'
    if (-not $IsWindows) {
        $linkedWorker = Join-Path $temporaryRoot 'linked-worker'
        [void](New-Item -ItemType SymbolicLink -Path $linkedWorker -Target $repository)
        $profiles.profiles['fixture-fast'].postflight.arguments = @('-NoProfile', '-File', (Join-Path $linkedWorker 'worker-gate.ps1'))
        Write-RoutingJson $runnerConfig $profiles
        & pwsh -NoProfile -File $runner -Action Validate -State $statePath `
            -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot *> $null
        Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Symlinked postflight gate was accepted'
    }
    $profiles.profiles['fixture-fast'].postflight.arguments = @('-NoProfile', '-File', $fixtureRunner, '-CheckPayload', '{payloadPath}', '-Content', '{command}')
    Write-RoutingJson $runnerConfig $profiles

    $first = @(& pwsh -NoProfile -File $runner -Action Run -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot -PhaseId 'read-intake' 2>&1)
    if ($LASTEXITCODE -ne 0) {
        $logText = @(Get-ChildItem -LiteralPath $repository -Filter '*.log.txt' -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue }) -join [Environment]::NewLine
        throw "Fast phase failed: $($first -join [Environment]::NewLine); runner log: $logText"
    }
    $afterFirst = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    Assert-RoutingTest ($afterFirst.routing.phases[0].status -eq 'Completed') 'Fast phase did not complete'
    Assert-RoutingTest ($afterFirst.routing.phases[0].model -eq 'fixture-fast-model') 'Fast model metadata missing'
    Assert-RoutingTest ($afterFirst.routing.phases[1].status -eq 'Pending') 'Dependent phase changed prematurely'
    Assert-RoutingTest ((Get-FileHash -LiteralPath $outsideLog -Algorithm SHA256).Hash -ceq $outsideLogHash) `
        'Runner redirected coordinator log output through a symlink'
    Assert-RoutingTest ((Get-FileHash -LiteralPath $outsideState -Algorithm SHA256).Hash -ceq $outsideStateHash) `
        'Runner redirected atomic state write through a predictable temp path'
    if (-not $IsWindows) {
        $firstLog = Join-Path $repository ".specify/runtime/autonomous-routing/$($afterFirst.runId)/read-intake.$($afterFirst.routing.phases[0].attemptId).log.txt"
        Assert-RoutingTest ((Get-Item -LiteralPath $firstLog -Force).LinkType -eq 'SymbolicLink') `
            'Malicious fixture did not replace the log pathname'
        $legacyLinks = @(Get-ChildItem -LiteralPath $featureDirectory -Filter 'autonomous-run-state.json.tmp.*' -Force |
            Where-Object { $_.LinkType -eq 'SymbolicLink' })
        Assert-RoutingTest ($legacyLinks.Count -ge 1) 'Malicious fixture did not create the predictable temp symlink'
    }

    $second = @(& pwsh -NoProfile -File $runner -Action Run -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot -PhaseId 'plan' 2>&1)
    Assert-RoutingTest ($LASTEXITCODE -eq 0) "Frontier phase failed: $($second -join [Environment]::NewLine)"
    $afterSecond = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    Assert-RoutingTest ($afterSecond.routing.phases[1].status -eq 'Completed') 'Frontier phase did not complete'
    Assert-RoutingTest ($afterSecond.routing.phases[1].model -eq 'fixture-frontier-model') 'Frontier model metadata missing'
    Assert-RoutingTest ($afterSecond.routing.phases[1].resultSha256 -match '^[0-9a-f]{64}$') 'Result hash missing'
    Assert-RoutingTest ((Get-FileHash -LiteralPath $outsideLog -Algorithm SHA256).Hash -ceq $outsideLogHash) `
        'Second runner redirected coordinator log output through a symlink'
    Assert-RoutingTest ((Get-FileHash -LiteralPath $outsideState -Algorithm SHA256).Hash -ceq $outsideStateHash) `
        'Second runner redirected atomic state write through a predictable temp path'

    $unsafeRunPath = Join-Path $featureDirectory 'unsafe-run-id-state.json'
    $unsafeRun = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
    $unsafeRun.runId = '../escape'
    Write-RoutingJson $unsafeRunPath $unsafeRun
    & pwsh -NoProfile -File $runner -Action Status -State $unsafeRunPath -RoutingRoot $allPresetRoot *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Unsafe runId reached routing output paths'

    $unsafePhasePath = Join-Path $featureDirectory 'unsafe-phase-id-state.json'
    $unsafePhase = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
    $unsafePhase.routing.phases[0].phaseId = '../escape'
    Write-RoutingJson $unsafePhasePath $unsafePhase
    & pwsh -NoProfile -File $runner -Action Validate -State $unsafePhasePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Unsafe phaseId reached routing output paths'

    $terminalPath = Join-Path $featureDirectory 'terminal-authority-state.json'
    $terminal = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
    $terminal.status = 'Completed'
    $terminal.nextExactAction = 'N/A'
    $terminal.closeout.finalValidation = 'Completed'
    $terminal.authorityRevalidationRequired = $true
    Write-RoutingJson $terminalPath $terminal
    $statePs = Join-Path $presetRoot 'scripts/validate-autonomous-run-state.ps1'
    $stateSh = Join-Path $presetRoot 'scripts/validate-autonomous-run-state.sh'
    & pwsh -NoProfile -File $statePs -State $terminalPath *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Completed PowerShell state retained authority marker'
    & bash $stateSh --state $terminalPath *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Completed Bash state retained authority marker'
    $terminal.authorityRevalidationRequired = $false
    Write-RoutingJson $terminalPath $terminal
    & pwsh -NoProfile -File $statePs -State $terminalPath *> $null
    Assert-RoutingTest ($LASTEXITCODE -eq 0) 'Completed PowerShell state rejected cleared authority marker'
    & bash $stateSh --state $terminalPath *> $null
    Assert-RoutingTest ($LASTEXITCODE -eq 0) 'Completed Bash state rejected cleared authority marker'

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
    Assert-RoutingTest ($routingFiles.Count -eq 2) 'The isolated composition fixture must contain the shipped and synthetic catalogs'
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

    if (-not $IsWindows) {
        $outsideParent = Join-Path $temporaryRoot 'outside-state-parent'
        [void](New-Item -ItemType Directory -Path $outsideParent)
        $outsideStateFile = Join-Path $outsideParent 'parent-swap-state.json'
        Copy-Item -LiteralPath $statePath -Destination $outsideStateFile
        $sentinelHash = (Get-FileHash -LiteralPath $outsideStateFile -Algorithm SHA256).Hash
        $swapStatePath = Join-Path $featureDirectory 'parent-swap-state.json'
        $swapState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json -AsHashtable
        $swapState.routing.phases[0].status = 'Pending'
        Write-RoutingJson $swapStatePath $swapState
        $profiles.profiles['fixture-fast'].arguments += @('-StateParentSymlinkTarget', $outsideParent)
        Write-RoutingJson $runnerConfig $profiles
        & pwsh -NoProfile -File $runner -Action Run -State $swapStatePath `
            -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot -PhaseId 'read-intake' *> $null
        Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Worker-controlled State parent redirection was accepted'
        Assert-RoutingTest ((Get-FileHash -LiteralPath $outsideStateFile -Algorithm SHA256).Hash -ceq $sentinelHash) `
            'Coordinator wrote State through the worker-controlled parent symlink'
        Assert-RoutingTest (@(Get-ChildItem -LiteralPath $outsideParent -Filter 'parent-swap-state.json.tmp.*').Count -eq 0) `
            'Coordinator created a State temporary file outside the worktree'
        & pwsh -NoProfile -File $runner -Action Status -State $swapStatePath `
            -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot *> $null
        Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Preexisting external State parent symlink was accepted'
        Remove-Item -LiteralPath $featureDirectory -Force
        Move-Item -LiteralPath "${featureDirectory}.held" -Destination $featureDirectory
    }

    $compositionCatalog.commands['speckit.plan'] = 'invalid-role'
    Write-RoutingJson $compositionCatalogPath $compositionCatalog
    & pwsh -NoProfile -File $runner -Action Validate -State $statePath `
        -RunnerConfig $runnerConfig -RoutingRoot $allPresetRoot *> $null
    Assert-RoutingTest ($LASTEXITCODE -ne 0) 'Invalid catalog role was accepted'

    Write-Output 'PASS: balanced command routing, phase switching, fail-closed validation, and script-only separation'
} finally {
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
}
