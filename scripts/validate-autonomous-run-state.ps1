<#
.SYNOPSIS
Prueft den wiederaufnehmbaren Zustand eines autonomen Spec-Kit-Laufs.

Validates resumable state for an autonomous Spec Kit run.

.DESCRIPTION
Die Pruefung ist read-only. Sie startet, stoppt oder setzt keinen Lauf fort und
verleiht keine Commit-, Push-, PR-, Merge- oder Provider-Rechte.

The validator is read-only. It does not start, stop, or resume a run and grants
no commit, push, pull-request, merge, or provider authority.

.PARAMETER State
Feature-lokale Datei autonomous-run-state.json.

Feature-local autonomous-run-state.json file.

.EXAMPLE
pwsh -NoProfile -File scripts/validate-autonomous-run-state.ps1 -State specs/028-feature/autonomous-run-state.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$State
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-AutonomousRunState {
    <#
    .SYNOPSIS
    Prueft Schema und Zustandsuebergaenge eines autonomen Laufs.

    Validates schema and state transitions for an autonomous run.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$State
    )

    $Errors = [System.Collections.Generic.List[string]]::new()

    function Get-TextProperty {
        param([object]$Object, [string]$Name)
        if ($null -eq $Object) { return '' }
        $Property = $Object.PSObject.Properties[$Name]
        if ($null -eq $Property) { return '' }
        if ($Property.Value -is [DateTime]) {
            return $Property.Value.ToUniversalTime().ToString(
                'yyyy-MM-ddTHH:mm:ss.FFFFFFFZ',
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        }
        if ($Property.Value -is [DateTimeOffset]) {
            return $Property.Value.UtcDateTime.ToString(
                'yyyy-MM-ddTHH:mm:ss.FFFFFFFZ',
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        }
        if ($Property.Value -isnot [string]) { return '' }
        return ([string]$Property.Value).Trim()
    }

    function Get-RequiredText {
        param([object]$Object, [string]$Name, [string]$Label)
        $Value = Get-TextProperty -Object $Object -Name $Name
        if ([string]::IsNullOrWhiteSpace($Value)) {
            $Errors.Add("$Label.$Name must be a non-empty string")
        }
        return $Value
    }

    function Test-RelativePath {
        param([string]$Value)
        if ([System.IO.Path]::IsPathRooted($Value)) { return $false }
        return -not ($Value -split '[\\/]' | Where-Object { $_ -eq '..' })
    }

    function Test-UtcTimestamp {
        param([string]$Value)
        $Parsed = [DateTimeOffset]::MinValue
        return $Value.EndsWith('Z') -and [DateTimeOffset]::TryParse(
            $Value,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal,
            [ref]$Parsed
        )
    }

    if (-not (Test-Path -LiteralPath $State -PathType Leaf)) {
        throw "State file not found: $State"
    }
    try {
        $Data = Get-Content -LiteralPath $State -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        throw "State is not valid UTF-8 JSON: $($_.Exception.Message)"
    }

    if ((Get-TextProperty -Object $Data -Name 'schemaVersion') -ne '1.0') {
        $Errors.Add('State schemaVersion must be 1.0')
    }

    $RunId = Get-RequiredText -Object $Data -Name 'runId' -Label 'state'
    $ParsedRunId = [Guid]::Empty
    if (-not [Guid]::TryParse($RunId, [ref]$ParsedRunId) -or $ParsedRunId -eq [Guid]::Empty) {
        $Errors.Add('State.runId must be a non-zero UUID')
    }

    $FeaturePath = Get-RequiredText -Object $Data -Name 'featurePath' -Label 'state'
    if (-not $FeaturePath.StartsWith('specs/') -or -not (Test-RelativePath -Value $FeaturePath)) {
        $Errors.Add('State.featurePath must be a relative path below specs/')
    }
    [void](Get-RequiredText -Object $Data -Name 'branch' -Label 'state')

    $DeliveryMode = Get-RequiredText -Object $Data -Name 'deliveryMode' -Label 'state'
    if ($DeliveryMode -notin @('LocalImplementation', 'PublishPR', 'MergeAndSync')) {
        $Errors.Add('State.deliveryMode must be LocalImplementation, PublishPR, or MergeAndSync')
    }

    $AuthorityProperty = $Data.PSObject.Properties['authorityRevalidationRequired']
    if ($null -eq $AuthorityProperty -or $AuthorityProperty.Value -isnot [bool]) {
        $Errors.Add('State.authorityRevalidationRequired must be boolean')
    }
    $Authority = $null -ne $AuthorityProperty -and $AuthorityProperty.Value -eq $true

    $Stage = Get-RequiredText -Object $Data -Name 'stage' -Label 'state'
    $Stages = @('Preflight', 'Specify', 'Clarify', 'Checklists', 'Plan', 'PlanReview', 'Tasks', 'Analyze', 'Implement', 'Validate', 'Publish', 'Review', 'MergeAndSync', 'Retrospective')
    if ($Stage -notin $Stages) { $Errors.Add('State.stage is not an allowed autonomous-run stage') }

    $Status = Get-RequiredText -Object $Data -Name 'status' -Label 'state'
    $Statuses = @('Active', 'StopRequested', 'PausedByUser', 'Interrupted', 'Blocked', 'Completed')
    if ($Status -notin $Statuses) { $Errors.Add('State.status is not an allowed autonomous-run status') }

    $Checkpoint = Get-RequiredText -Object $Data -Name 'checkpointCommit' -Label 'state'
    if ($Checkpoint -ne 'N/A' -and $Checkpoint -notmatch '^(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})$') {
        $Errors.Add('State.checkpointCommit must be N/A or a full Git object ID')
    }

    $ArtifactProperty = $Data.PSObject.Properties['acceptedArtifacts']
    if ($null -eq $ArtifactProperty -or $null -eq $ArtifactProperty.Value) {
        $Errors.Add('State.acceptedArtifacts must be an array')
        $Artifacts = @()
    } else {
        $Artifacts = @($ArtifactProperty.Value)
    }
    $ArtifactPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    for ($Index = 0; $Index -lt $Artifacts.Count; $Index++) {
        $Artifact = $Artifacts[$Index]
        $Label = "state.acceptedArtifacts[$Index]"
        $ArtifactPath = Get-RequiredText -Object $Artifact -Name 'path' -Label $Label
        $ArtifactHash = Get-RequiredText -Object $Artifact -Name 'sha256' -Label $Label
        if (-not (Test-RelativePath -Value $ArtifactPath)) { $Errors.Add("$Label.path must be repository-relative without ..") }
        if (-not $ArtifactPaths.Add($ArtifactPath)) { $Errors.Add("Duplicate accepted artifact path: $ArtifactPath") }
        if ($ArtifactHash -notmatch '^[0-9a-f]{64}$') { $Errors.Add("$Label.sha256 must be lowercase SHA-256") }
    }

    $TasksProperty = $Data.PSObject.Properties['tasks']
    $Tasks = if ($null -eq $TasksProperty) { $null } else { $TasksProperty.Value }
    if ($null -eq $Tasks) { $Errors.Add('State.tasks must be an object') }
    $TasksPath = Get-RequiredText -Object $Tasks -Name 'path' -Label 'state.tasks'
    $TasksHash = Get-RequiredText -Object $Tasks -Name 'sha256' -Label 'state.tasks'
    $CompletedProperty = if ($null -eq $Tasks) { $null } else { $Tasks.PSObject.Properties['completed'] }
    $TotalProperty = if ($null -eq $Tasks) { $null } else { $Tasks.PSObject.Properties['total'] }
    $Completed = if ($null -eq $CompletedProperty) { -1 } else { $CompletedProperty.Value }
    $Total = if ($null -eq $TotalProperty) { -1 } else { $TotalProperty.Value }
    if ($Completed -isnot [long] -and $Completed -isnot [int]) { $Errors.Add('State.tasks.completed must be a non-negative integer') }
    elseif ($Completed -lt 0) { $Errors.Add('State.tasks.completed must be a non-negative integer') }
    if ($Total -isnot [long] -and $Total -isnot [int]) { $Errors.Add('State.tasks.total must be a non-negative integer') }
    elseif ($Total -lt 0) { $Errors.Add('State.tasks.total must be a non-negative integer') }
    if ($Completed -is [ValueType] -and $Total -is [ValueType] -and $Completed -gt $Total) {
        $Errors.Add('State.tasks.completed cannot exceed state.tasks.total')
    }
    if ($TasksPath -eq 'N/A') {
        if ($TasksHash -ne 'N/A' -or $Completed -ne 0 -or $Total -ne 0) {
            $Errors.Add('State.tasks N/A path requires N/A hash and zero counts')
        }
    } elseif (-not (Test-RelativePath -Value $TasksPath)) {
        $Errors.Add('State.tasks.path must be repository-relative without ..')
    } elseif ($TasksHash -notmatch '^[0-9a-f]{64}$') {
        $Errors.Add('State.tasks.sha256 must be lowercase SHA-256')
    }

    [void](Get-RequiredText -Object $Data -Name 'lastPassingGate' -Label 'state')
    $NextAction = Get-RequiredText -Object $Data -Name 'nextExactAction' -Label 'state'

    $OperationProperty = $Data.PSObject.Properties['lastOperation']
    $Operation = if ($null -eq $OperationProperty) { $null } else { $OperationProperty.Value }
    if ($null -eq $Operation) { $Errors.Add('State.lastOperation must be an object') }
    [void](Get-RequiredText -Object $Operation -Name 'kind' -Label 'state.lastOperation')
    $OperationState = Get-RequiredText -Object $Operation -Name 'state' -Label 'state.lastOperation'
    if ($OperationState -notin @('N/A', 'Completed', 'Failed', 'NeedsRevalidation')) {
        $Errors.Add('State.lastOperation.state is not allowed')
    }
    [void](Get-RequiredText -Object $Operation -Name 'summary' -Label 'state.lastOperation')

    $StopProperty = $Data.PSObject.Properties['stop']
    $Stop = if ($null -eq $StopProperty) { $null } else { $StopProperty.Value }
    if ($null -eq $Stop) { $Errors.Add('State.stop must be an object') }
    $StopReason = Get-RequiredText -Object $Stop -Name 'reason' -Label 'state.stop'
    $RequestedAt = Get-RequiredText -Object $Stop -Name 'requestedAt' -Label 'state.stop'
    $SafeBoundary = Get-RequiredText -Object $Stop -Name 'safeBoundary' -Label 'state.stop'

    $UpdatedAt = Get-RequiredText -Object $Data -Name 'updatedAt' -Label 'state'
    if (-not (Test-UtcTimestamp -Value $UpdatedAt)) { $Errors.Add('State.updatedAt must be an ISO-8601 UTC timestamp ending in Z') }

    $Stopped = $Status -in @('StopRequested', 'PausedByUser', 'Interrupted', 'Blocked')
    if ($Stopped) {
        if (-not $Authority) { $Errors.Add("State.authorityRevalidationRequired must be true for $Status") }
        if ($StopReason -eq 'N/A' -or $SafeBoundary -eq 'N/A') {
            $Errors.Add("State.stop reason and safeBoundary must be recorded for $Status")
        }
        if ($RequestedAt -eq 'N/A' -or -not (Test-UtcTimestamp -Value $RequestedAt)) {
            $Errors.Add("State.stop.requestedAt must be a UTC timestamp for $Status")
        }
    } elseif ($StopReason -ne 'N/A' -or $RequestedAt -ne 'N/A' -or $SafeBoundary -ne 'N/A') {
        $Errors.Add("State.stop fields must be N/A for $Status")
    }

    if ($Status -eq 'Interrupted' -and $OperationState -notin @('Failed', 'NeedsRevalidation', 'N/A')) {
        $Errors.Add('Interrupted state cannot claim the last operation completed')
    }
    if ($Status -eq 'Completed' -and $NextAction -ne 'N/A') {
        $Errors.Add('Completed state requires nextExactAction N/A')
    }

    if ($Errors.Count -gt 0) {
        foreach ($Message in $Errors) { [Console]::Error.WriteLine("ERROR: $Message") }
        throw "Autonomous run-state validation failed with $($Errors.Count) error(s)."
    }

    return "PASS: run $RunId, feature $FeaturePath, stage $Stage, status $Status, tasks ${Completed}/${Total}"
}

if ($MyInvocation.InvocationName -ne '.') {
    Test-AutonomousRunState -State $State
}
