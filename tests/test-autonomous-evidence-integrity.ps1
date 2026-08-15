#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-EvidenceTest([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Write-JsonFile([string]$Path, [object]$Value) {
    $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function Get-NormalizedHash([string]$Path) {
    $Bytes = [IO.File]::ReadAllBytes($Path)
    $Offset = if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) { 3 } else { 0 }
    $Text = [Text.UTF8Encoding]::new($false, $true).GetString($Bytes, $Offset, $Bytes.Length - $Offset)
    $Normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
    return [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($Normalized))
    ).ToLowerInvariant()
}

function Invoke-Expected([scriptblock]$Command, [int]$ExpectedExit, [string]$Label) {
    $Output = @(& $Command 2>&1)
    $Actual = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    Assert-EvidenceTest ($Actual -eq $ExpectedExit) "$Label expected exit $ExpectedExit, got ${Actual}: $($Output -join ' ')"
    return $Output
}

$PresetRoot = Split-Path -Parent $PSScriptRoot
$Scripts = Join-Path $PresetRoot 'scripts'
$DeliveryPs = Join-Path $Scripts 'validate-autonomous-delivery-set.ps1'
$DeliverySh = Join-Path $Scripts 'validate-autonomous-delivery-set.sh'
$PhasePs = Join-Path $Scripts 'validate-autonomous-phase-result.ps1'
$PhaseSh = Join-Path $Scripts 'validate-autonomous-phase-result.sh'
$GatePs = Join-Path $Scripts 'validate-autonomous-gate-evidence.ps1'
$GateSh = Join-Path $Scripts 'validate-autonomous-gate-evidence.sh'
$HasBash = $null -ne (Get-Command bash -ErrorAction SilentlyContinue)
$Root = Join-Path ([IO.Path]::GetTempPath()) "autonomous-evidence-$([guid]::NewGuid())"
$Repo = Join-Path $Root 'repo'

try {
    [void](New-Item -ItemType Directory -Path $Repo -Force)
    & git -C $Repo init --quiet
    & git -C $Repo config user.name Fixture
    & git -C $Repo config user.email fixture@example.invalid
    [IO.File]::WriteAllText((Join-Path $Repo 'tracked.txt'), "baseline`n", [Text.UTF8Encoding]::new($false))
    & git -C $Repo add tracked.txt
    & git -C $Repo commit --quiet -m baseline
    [IO.File]::WriteAllText((Join-Path $Repo '.gitignore'), ".runtime/`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $Repo 'tracked.txt'), "changed`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $Repo 'delivery.txt'), "delivery`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $Repo 'unrelated.txt'), "unrelated`n", [Text.UTF8Encoding]::new($false))
    [void](New-Item -ItemType Directory -Path (Join-Path $Repo '.runtime') -Force)
    [IO.File]::WriteAllText((Join-Path $Repo '.runtime/evidence.txt'), "ignored`n", [Text.UTF8Encoding]::new($false))
    $Before = (& git -C $Repo status --porcelain=v1 --untracked-files=all --ignored) -join "`n"

    $PsDelivery = Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended delivery.txt } 0 'PowerShell delivery pass'
    Assert-EvidenceTest (($PsDelivery -join "`n") -match 'unrelated.txt') 'Unrelated untracked path was not reported'
    if ($HasBash) {
        $ShDelivery = Invoke-Expected { & bash $DeliverySh --repo $Repo --intended delivery.txt } 0 'Bash delivery pass'
        Assert-EvidenceTest (($ShDelivery -join "`n") -match 'unrelated.txt') 'Bash unrelated path was not reported'
    }
    $After = (& git -C $Repo status --porcelain=v1 --untracked-files=all --ignored) -join "`n"
    Assert-EvidenceTest ($Before -eq $After) 'Delivery validation changed repository state'

    [IO.File]::WriteAllText((Join-Path $Repo 'delivery.txt'), "bad `n", [Text.UTF8Encoding]::new($false))
    [void](Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended delivery.txt } 2 'PowerShell whitespace rejection')
    if ($HasBash) { [void](Invoke-Expected { & bash $DeliverySh --repo $Repo --intended delivery.txt } 2 'Bash whitespace rejection') }
    [IO.File]::WriteAllText((Join-Path $Repo 'delivery.txt'), "delivery`n", [Text.UTF8Encoding]::new($false))
    [void](Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended ../escape.txt } 2 'Traversal rejection')
    [void](Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended (Join-Path $Repo 'delivery.txt') } 2 'Absolute path rejection')
    [void](Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended missing.txt } 2 'Missing path rejection')
    [void](Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended delivery.txt,delivery.txt } 2 'Duplicate path rejection')
    [void](Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended .runtime/evidence.txt } 2 'Ignored path rejection')
    [void](Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended .runtime } 2 'Directory rejection')
    if (-not $IsWindows) {
        & ln -s delivery.txt (Join-Path $Repo 'delivery-link.txt')
        [void](Invoke-Expected { & pwsh -NoProfile -File $DeliveryPs -Repo $Repo -Intended delivery-link.txt } 2 'Symlink rejection')
    }

    $Payload = Join-Path $Repo 'phase.payload.txt'
    [IO.File]::WriteAllText($Payload, "payload`n", [Text.UTF8Encoding]::new($false))
    $PhaseResult = Join-Path $Repo 'phase-result.json'
    $Phase = [ordered]@{
        schemaVersion = '1.0'; phaseId = 'implement'; attemptId = [guid]::NewGuid().ToString()
        outcome = 'Completed'; expectedTasks = 4; completedTasks = 4; blockedReason = ''
        gatesSatisfied = $true; payloadPath = 'phase.payload.txt'; payloadSha256 = (Get-NormalizedHash $Payload)
    }
    Write-JsonFile $PhaseResult $Phase
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId implement -ExitCode 0 } 0 'PowerShell phase pass')
    if ($HasBash) { [void](Invoke-Expected { & bash $PhaseSh --repo $Repo --result $PhaseResult --phase-id implement --exit-code 0 } 0 'Bash phase pass') }
    $Phase.outcome = 'Blocked'; $Phase.completedTasks = 3; $Phase.blockedReason = 'fixture blocker'
    Write-JsonFile $PhaseResult $Phase
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId implement -ExitCode 0 } 3 'PowerShell semantic block')
    if ($HasBash) { [void](Invoke-Expected { & bash $PhaseSh --repo $Repo --result $PhaseResult --phase-id implement --exit-code 0 } 3 'Bash semantic block') }
    $Phase.outcome = 'Completed'; $Phase.completedTasks = 4; $Phase.blockedReason = ''; $Phase.payloadSha256 = ('0' * 64)
    Write-JsonFile $PhaseResult $Phase
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId implement -ExitCode 0 } 3 'Payload hash rejection')
    $Phase.payloadSha256 = (Get-NormalizedHash $Payload); Write-JsonFile $PhaseResult $Phase
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId wrong-phase -ExitCode 0 } 3 'Wrong phase rejection')
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId implement -ExitCode 1 } 3 'Non-zero process rejection')
    $MissingResult = Join-Path $Repo 'missing-result.json'
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $MissingResult -PhaseId implement -ExitCode 0 } 2 'Missing result rejection')
    [IO.File]::WriteAllText($PhaseResult, '', [Text.UTF8Encoding]::new($false))
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId implement -ExitCode 0 } 2 'Empty result rejection')
    [IO.File]::WriteAllText($PhaseResult, '{not-json}', [Text.UTF8Encoding]::new($false))
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId implement -ExitCode 0 } 2 'Malformed result rejection')
    [IO.File]::WriteAllText($PhaseResult, '{"schemaVersion":', [Text.UTF8Encoding]::new($false))
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId implement -ExitCode 0 } 2 'Truncated result rejection')
    $PhaseText = ($Phase | ConvertTo-Json -Depth 10).Replace("`n", "`r`n")
    [IO.File]::WriteAllText($PhaseResult, $PhaseText, [Text.UTF8Encoding]::new($true))
    [void](Invoke-Expected { & pwsh -NoProfile -File $PhasePs -Repo $Repo -Result $PhaseResult -PhaseId implement -ExitCode 0 } 0 'BOM and CRLF phase pass')

    $Requirements = Join-Path $Repo 'requirements.json'
    $RequirementData = [ordered]@{ schemaVersion = '1.0'; gates = @(
        [ordered]@{ gateId = 'G1'; applicability = 'Applicable'; requiredScope = 'fixture'; requiredCommandTokens = @('verify'); requiredRunnerOrPlatformTokens = @(); rationale = ''; reevaluationTrigger = '' },
        [ordered]@{ gateId = 'G2'; applicability = 'N/A'; requiredScope = 'release'; requiredCommandTokens = @(); requiredRunnerOrPlatformTokens = @(); rationale = 'No release'; reevaluationTrigger = 'Release requested' }
    ) }
    Write-JsonFile $Requirements $RequirementData
    $Head = (& git -C $Repo rev-parse HEAD).Trim()
    $Entries = @(
        [ordered]@{ gateId = 'G1'; evidenceRole = 'Primary'; applicability = 'Applicable'; requiredScope = 'fixture'; headSha = $Head; provider = 'Local'; runId = 'run-1'; workflow = 'fixture'; job = 'fixture'; runnerOrPlatform = 'local'; executedCommand = 'verify fixture'; result = 'Pass'; evidenceReference = 'local:fixture'; rationale = ''; reevaluationTrigger = ''; supplementalFor = '' },
        [ordered]@{ gateId = 'G2'; evidenceRole = 'Primary'; applicability = 'N/A'; requiredScope = 'release'; headSha = $Head; provider = 'N/A'; runId = 'N/A'; workflow = 'N/A'; job = 'N/A'; runnerOrPlatform = 'N/A'; executedCommand = 'N/A'; result = 'N/A'; evidenceReference = 'local:scope'; rationale = 'No release'; reevaluationTrigger = 'Release requested'; supplementalFor = '' }
    )
    $PrePath = Join-Path $Repo 'pre.json'
    $Pre = [ordered]@{ schemaVersion = '2.0'; snapshotType = 'PreMerge'; snapshotId = [guid]::NewGuid().ToString(); capturedAt = '2026-08-15T00:00:00Z'; requirementsSha256 = (Get-NormalizedHash $Requirements); reviewedHead = $Head; acceptedPreMergePath = ''; acceptedPreMergeSha256 = ''; mergeCommit = ''; changedPaths = @(); entries = $Entries }
    Write-JsonFile $PrePath $Pre
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PrePath -Head $Head } 0 'PowerShell PreMerge pass')
    if ($HasBash) { [void](Invoke-Expected { & bash $GateSh --requirements $Requirements --evidence $PrePath --head $Head } 0 'Bash PreMerge pass') }
    $Pre.mergeCommit = $Head; Write-JsonFile $PrePath $Pre
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PrePath -Head $Head } 2 'Premature merge rejection')
    $Pre.mergeCommit = ''; Write-JsonFile $PrePath $Pre
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PrePath -Head ('0' * 40) } 2 'Wrong reviewed head rejection')
    $Pre.requirementsSha256 = ('0' * 64); Write-JsonFile $PrePath $Pre
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PrePath -Head $Head } 2 'Wrong requirements hash rejection')
    $Pre.requirementsSha256 = (Get-NormalizedHash $Requirements); Write-JsonFile $PrePath $Pre

    $PostPath = Join-Path $Repo 'post.json'
    $Post = [ordered]@{ schemaVersion = '2.0'; snapshotType = 'PostMerge'; snapshotId = [guid]::NewGuid().ToString(); capturedAt = '2026-08-15T00:01:00Z'; requirementsSha256 = (Get-NormalizedHash $Requirements); reviewedHead = $Head; acceptedPreMergePath = $PrePath; acceptedPreMergeSha256 = (Get-NormalizedHash $PrePath); mergeCommit = $Head; changedPaths = @(); entries = $Entries }
    Write-JsonFile $PostPath $Post
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PostPath -Head $Head -MergeCommit $Head } 0 'PowerShell PostMerge pass')
    if ($HasBash) { [void](Invoke-Expected { & bash $GateSh --requirements $Requirements --evidence $PostPath --head $Head --merge-commit $Head } 0 'Bash PostMerge pass') }
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PostPath -Head $Head -MergeCommit ('0' * 40) } 2 'Merge commit mismatch rejection')
    $Post.acceptedPreMergeSha256 = ('f' * 64); Write-JsonFile $PostPath $Post
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PostPath -Head $Head -MergeCommit $Head } 2 'PreMerge hash rejection')
    $Post.acceptedPreMergeSha256 = (Get-NormalizedHash $PrePath); $Post.changedPaths = @('unexpected.txt'); Write-JsonFile $PostPath $Post
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PostPath -Head $Head -MergeCommit $Head } 2 'PostMerge delta rejection')
    $Post.changedPaths = @(); Write-JsonFile $PostPath $Post
    $AcceptedHash = $Post.acceptedPreMergeSha256
    $Pre.capturedAt = '2026-08-15T00:00:01Z'; Write-JsonFile $PrePath $Pre
    $Post.acceptedPreMergeSha256 = $AcceptedHash; Write-JsonFile $PostPath $Post
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $PostPath -Head $Head -MergeCommit $Head } 2 'Mutated PreMerge rejection')

    $HistoricalPath = Join-Path $Repo 'historical.json'
    $Historical = [ordered]@{ schemaVersion = '1.0'; requirementsSha256 = (Get-NormalizedHash $Requirements); reviewedHead = $Head; entries = $Entries }
    Write-JsonFile $HistoricalPath $Historical
    [void](Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $HistoricalPath -Head $Head } 2 'Legacy new-delivery rejection')
    $HistoryOutput = Invoke-Expected { & pwsh -NoProfile -File $GatePs -Requirements $Requirements -Evidence $HistoricalPath -Head $Head -Historical } 0 'Historical audit pass'
    Assert-EvidenceTest (($HistoryOutput -join "`n") -match 'HistoricalOnly') 'Historical evidence appeared merge-authorizing'

    Write-Output 'PASS: delivery-set, semantic phase-result, lifecycle evidence, historical mode, and cross-shell parity'
} finally {
    Remove-Item -LiteralPath $Root -Recurse -Force -ErrorAction SilentlyContinue
}
