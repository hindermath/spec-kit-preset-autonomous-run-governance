<#
.SYNOPSIS
Prueft Gate-Anforderungen und exakte Ausfuehrungsnachweise eines autonomen Laufs.

Validates gate requirements and exact execution evidence for an autonomous run.

.DESCRIPTION
Die Pruefung ist read-only und verleiht keine Commit-, Push-, PR-, Merge-,
Bypass- oder Provider-Administrationsrechte.

The validator is read-only and grants no commit, push, pull-request, merge,
bypass, or provider-administration authority.

.PARAMETER Requirements
JSON-Datei mit den vor der Auslieferung akzeptierten Gate-Anforderungen.

JSON file containing gate requirements accepted before delivery.

.PARAMETER Evidence
JSON-Datei mit providerneutraler Ausfuehrungsevidence fuer den geprueften Head.

JSON file containing provider-neutral execution evidence for the reviewed head.

.PARAMETER Head
Vollstaendige 40- oder 64-stellige Git-Objekt-ID des geprueften Heads.

Full 40- or 64-character Git object ID of the reviewed head.

.EXAMPLE
pwsh -NoProfile -File scripts/validate-autonomous-gate-evidence.ps1 -Requirements gates.json -Evidence evidence.json -Head $sha
#>
[CmdletBinding()]
param(
    [string]$Requirements = '',

    [string]$Evidence = '',

    [string]$Head = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-AutonomousGateEvidence {
    <#
    .SYNOPSIS
    Prueft Gate-Anforderungen gegen exakte Head-Evidence.

    Validates gate requirements against exact-head evidence.

    .DESCRIPTION
    Die Advanced Function ist read-only. Sie verleiht keine Remote-Rechte.

    The advanced function is read-only. It grants no remote authority.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Requirements,

        [Parameter(Mandatory)]
        [string]$Evidence,

        [Parameter(Mandatory)]
        [string]$Head
    )

$Errors = [System.Collections.Generic.List[string]]::new()

function Get-TextProperty {
    param(
        [object]$Object,
        [string]$Name
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return '' }
    if ($property.Value -isnot [string]) { return '' }
    return [string]$property.Value
}

function Get-ArrayProperty {
    param(
        [object]$Object,
        [string]$Name,
        [string]$Label
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        $Errors.Add("$Label must be an array of non-empty strings")
        return @()
    }
    $items = @($property.Value)
    foreach ($item in $items) {
        if ($item -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$item)) {
            $Errors.Add("$Label must be an array of non-empty strings")
            return @()
        }
    }
    return $items
}

function Test-NonEmpty {
    param([object]$Object, [string]$Name)
    return -not [string]::IsNullOrWhiteSpace((Get-TextProperty -Object $Object -Name $Name))
}

if (-not (Test-Path -LiteralPath $Requirements -PathType Leaf)) {
    throw "Requirements file not found: $Requirements"
}
if (-not (Test-Path -LiteralPath $Evidence -PathType Leaf)) {
    throw "Evidence file not found: $Evidence"
}
if ($Head -notmatch '^(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})$') {
    $Errors.Add('-Head must be a full 40- or 64-character hexadecimal Git object ID')
}

try {
    $RequirementsData = Get-Content -LiteralPath $Requirements -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    throw "Requirements is not valid UTF-8 JSON: $($_.Exception.Message)"
}
try {
    $EvidenceData = Get-Content -LiteralPath $Evidence -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    throw "Evidence is not valid UTF-8 JSON: $($_.Exception.Message)"
}

$RequirementsById = @{}
if ((Get-TextProperty -Object $RequirementsData -Name 'schemaVersion') -ne '1.0') {
    $Errors.Add('Requirements schemaVersion must be 1.0')
}
$GateProperty = $RequirementsData.PSObject.Properties['gates']
$Gates = if ($null -eq $GateProperty) { @() } else { @($GateProperty.Value) }
if ($Gates.Count -eq 0) { $Errors.Add('Requirements gates must be a non-empty array') }

for ($Index = 0; $Index -lt $Gates.Count; $Index++) {
    $Gate = $Gates[$Index]
    $Label = "Requirements gate[$Index]"
    $GateId = (Get-TextProperty -Object $Gate -Name 'gateId').Trim()
    $Applicability = (Get-TextProperty -Object $Gate -Name 'applicability').Trim()
    $Scope = (Get-TextProperty -Object $Gate -Name 'requiredScope').Trim()
    if ([string]::IsNullOrWhiteSpace($GateId)) {
        $Errors.Add("$Label.gateId must be non-empty")
        continue
    }
    if ($RequirementsById.ContainsKey($GateId)) {
        $Errors.Add("Duplicate requirement gateId: $GateId")
        continue
    }
    if ($Applicability -notin @('Applicable', 'N/A')) {
        $Errors.Add("$Label.applicability must be Applicable or N/A")
    }
    if ([string]::IsNullOrWhiteSpace($Scope)) {
        $Errors.Add("$Label.requiredScope must be non-empty")
    }
    $CommandTokens = @(Get-ArrayProperty -Object $Gate -Name 'requiredCommandTokens' -Label "$Label.requiredCommandTokens")
    $RunnerTokens = @(Get-ArrayProperty -Object $Gate -Name 'requiredRunnerOrPlatformTokens' -Label "$Label.requiredRunnerOrPlatformTokens")
    $Rationale = (Get-TextProperty -Object $Gate -Name 'rationale').Trim()
    $Trigger = (Get-TextProperty -Object $Gate -Name 'reevaluationTrigger').Trim()
    if ($Applicability -eq 'Applicable' -and $CommandTokens.Count -eq 0) {
        $Errors.Add("$Label Applicable gates need at least one required command token")
    }
    if ($Applicability -eq 'N/A') {
        if ($CommandTokens.Count -gt 0 -or $RunnerTokens.Count -gt 0) {
            $Errors.Add("$Label N/A gates cannot require command or runner tokens")
        }
        if ([string]::IsNullOrWhiteSpace($Rationale)) { $Errors.Add("$Label N/A gates need a rationale") }
        if ([string]::IsNullOrWhiteSpace($Trigger)) { $Errors.Add("$Label N/A gates need a reevaluation trigger") }
    }
    $RequirementsById[$GateId] = [pscustomobject]@{
        Applicability = $Applicability
        RequiredScope = $Scope
        RequiredCommandTokens = $CommandTokens
        RequiredRunnerOrPlatformTokens = $RunnerTokens
        Rationale = $Rationale
        ReevaluationTrigger = $Trigger
    }
}

if ((Get-TextProperty -Object $EvidenceData -Name 'schemaVersion') -ne '1.0') {
    $Errors.Add('Evidence schemaVersion must be 1.0')
}
$ExpectedRequirementsHash = (Get-FileHash -LiteralPath $Requirements -Algorithm SHA256).Hash.ToLowerInvariant()
if ((Get-TextProperty -Object $EvidenceData -Name 'requirementsSha256').ToLowerInvariant() -ne $ExpectedRequirementsHash) {
    $Errors.Add('Evidence requirementsSha256 does not match the requirements file')
}
if ((Get-TextProperty -Object $EvidenceData -Name 'reviewedHead').ToLowerInvariant() -ne $Head.ToLowerInvariant()) {
    $Errors.Add('Evidence reviewedHead does not match -Head')
}

$EntryProperty = $EvidenceData.PSObject.Properties['entries']
$Entries = if ($null -eq $EntryProperty) { @() } else { @($EntryProperty.Value) }
if ($Entries.Count -eq 0) { $Errors.Add('Evidence entries must be a non-empty array') }
$EntriesById = @{}

for ($Index = 0; $Index -lt $Entries.Count; $Index++) {
    $Entry = $Entries[$Index]
    $Label = "Evidence entry[$Index]"
    $GateId = (Get-TextProperty -Object $Entry -Name 'gateId').Trim()
    $Role = (Get-TextProperty -Object $Entry -Name 'evidenceRole').Trim()
    if ([string]::IsNullOrWhiteSpace($GateId)) {
        $Errors.Add("$Label.gateId must be non-empty")
        continue
    }
    if (-not $RequirementsById.ContainsKey($GateId)) {
        $Errors.Add("$Label references undeclared gateId: $GateId")
        continue
    }
    if ($Role -notin @('Primary', 'Supplemental')) {
        $Errors.Add("$Label.evidenceRole must be Primary or Supplemental")
    }
    if (-not $EntriesById.ContainsKey($GateId)) {
        $EntriesById[$GateId] = [System.Collections.Generic.List[object]]::new()
    }
    $EntriesById[$GateId].Add($Entry)

    $Requirement = $RequirementsById[$GateId]
    $Applicability = (Get-TextProperty -Object $Entry -Name 'applicability').Trim()
    $Scope = (Get-TextProperty -Object $Entry -Name 'requiredScope').Trim()
    $EntryHead = (Get-TextProperty -Object $Entry -Name 'headSha').Trim()
    $Result = (Get-TextProperty -Object $Entry -Name 'result').Trim()
    if ($Applicability -ne $Requirement.Applicability) {
        $Errors.Add("$Label.applicability does not match requirement $GateId")
    }
    if ($Scope -ne $Requirement.RequiredScope) {
        $Errors.Add("$Label.requiredScope does not match requirement $GateId")
    }
    if ($EntryHead.ToLowerInvariant() -ne $Head.ToLowerInvariant()) {
        $Errors.Add("$Label.headSha does not match -Head")
    }

    if ($Applicability -eq 'Applicable') {
        foreach ($Field in @('provider', 'runId', 'workflow', 'job', 'runnerOrPlatform', 'executedCommand', 'evidenceReference')) {
            if (-not (Test-NonEmpty -Object $Entry -Name $Field)) {
                $Errors.Add("$Label.$Field must be non-empty for Applicable gates")
            }
        }
        if ($Result -ne 'Pass') { $Errors.Add("$Label.result must be Pass for Applicable gates") }
        $ExecutedCommand = Get-TextProperty -Object $Entry -Name 'executedCommand'
        $Runner = Get-TextProperty -Object $Entry -Name 'runnerOrPlatform'
        foreach ($Token in $Requirement.RequiredCommandTokens) {
            if (-not $ExecutedCommand.Contains([string]$Token)) {
                $Errors.Add("$Label.executedCommand is missing required token: $Token")
            }
        }
        foreach ($Token in $Requirement.RequiredRunnerOrPlatformTokens) {
            if (-not $Runner.Contains([string]$Token)) {
                $Errors.Add("$Label.runnerOrPlatform is missing required token: $Token")
            }
        }
        if ($Role -eq 'Supplemental' -and -not (Test-NonEmpty -Object $Entry -Name 'supplementalFor')) {
            $Errors.Add("$Label.supplementalFor is required for Supplemental evidence")
        }
    } elseif ($Applicability -eq 'N/A') {
        if ($Role -ne 'Primary') { $Errors.Add("$Label N/A evidence must be Primary") }
        if ($Result -ne 'N/A') { $Errors.Add("$Label.result must be N/A") }
        if ((Get-TextProperty -Object $Entry -Name 'rationale').Trim() -ne $Requirement.Rationale) {
            $Errors.Add("$Label.rationale does not match requirement $GateId")
        }
        if ((Get-TextProperty -Object $Entry -Name 'reevaluationTrigger').Trim() -ne $Requirement.ReevaluationTrigger) {
            $Errors.Add("$Label.reevaluationTrigger does not match requirement $GateId")
        }
        if (-not (Test-NonEmpty -Object $Entry -Name 'evidenceReference')) {
            $Errors.Add("$Label.evidenceReference must identify the N/A decision")
        }
    }
}

$SupplementalCount = 0
foreach ($GateId in $RequirementsById.Keys) {
    $Rows = if ($EntriesById.ContainsKey($GateId)) { @($EntriesById[$GateId]) } else { @() }
    $Primary = @($Rows | Where-Object { (Get-TextProperty -Object $_ -Name 'evidenceRole').Trim() -eq 'Primary' })
    if ($Primary.Count -ne 1) {
        $Errors.Add("Gate $GateId needs exactly one Primary evidence entry; found $($Primary.Count)")
    }
    if ($Primary.Count -eq 1) {
        $PrimaryReference = (Get-TextProperty -Object $Primary[0] -Name 'evidenceReference').Trim()
        foreach ($Row in $Rows) {
            if ((Get-TextProperty -Object $Row -Name 'evidenceRole').Trim() -eq 'Supplemental') {
                $SupplementalCount++
                if ((Get-TextProperty -Object $Row -Name 'supplementalFor').Trim() -ne $PrimaryReference) {
                    $Errors.Add("Gate $GateId Supplemental evidence must reference the Primary evidenceReference")
                }
            }
        }
    }
}

if ($Errors.Count -gt 0) {
    foreach ($Message in $Errors) { [Console]::Error.WriteLine("ERROR: $Message") }
    throw "Autonomous gate evidence validation failed with $($Errors.Count) error(s)."
}

Write-Output "PASS: $($RequirementsById.Count) gate requirements, $($RequirementsById.Count) primary entries, $SupplementalCount supplemental entries, reviewed head $Head"
}

if ($MyInvocation.InvocationName -ne '.') {
    Test-AutonomousGateEvidence -Requirements $Requirements -Evidence $Evidence -Head $Head
}
