#Requires -Version 7.0
[CmdletBinding()]
param(
    [string] $OutputFile = '',
    [string] $PhaseId = 'fixture',
    [string] $AttemptId = '',
    [string] $Content = 'fixture',
    [string] $LogFile = '',
    [string] $LogSymlinkTarget = '',
    [string] $StatePath = '',
    [string] $StateTempSymlinkTarget = '',
    [string] $StateParentSymlinkTarget = '',
    [string] $CoordinatorPid = '',
    [string] $CheckPayload = '',
    [int] $ExitCode = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($CheckPayload) {
    if (-not (Test-Path -LiteralPath $CheckPayload -PathType Leaf) -or
        [IO.File]::ReadAllText($CheckPayload).Trim() -cne $Content) { exit 1 }
    exit 0
}

if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
    if ($LogSymlinkTarget -and -not $IsWindows) {
        Remove-Item -LiteralPath $LogFile -Force
        [void](New-Item -ItemType SymbolicLink -Path $LogFile -Target $LogSymlinkTarget)
        Write-Output 'Runner output after replacing the log pathname.'
    }
    if ($StateTempSymlinkTarget -and -not $IsWindows) {
        $legacyTemporaryPath = "${StatePath}.tmp.$CoordinatorPid"
        if (-not (Test-Path -LiteralPath $legacyTemporaryPath)) {
            [void](New-Item -ItemType SymbolicLink -Path $legacyTemporaryPath -Target $StateTempSymlinkTarget)
        }
    }
    if ($StateParentSymlinkTarget -and -not $IsWindows) {
        $parent = Split-Path -Parent $StatePath
        Move-Item -LiteralPath $parent -Destination "${parent}.held"
        [void](New-Item -ItemType SymbolicLink -Path $parent -Target $StateParentSymlinkTarget)
    }
    $RepositoryDirectory = [IO.DirectoryInfo]::new((Split-Path -Parent $OutputFile))
    while ($null -ne $RepositoryDirectory -and
        -not (Test-Path -LiteralPath (Join-Path $RepositoryDirectory.FullName '.git'))) {
        $RepositoryDirectory = $RepositoryDirectory.Parent
    }
    if ($null -eq $RepositoryDirectory) { throw 'Fixture repository root not found' }
    $Repository = $RepositoryDirectory.FullName
    $PayloadFile = [IO.Path]::ChangeExtension($OutputFile, '.payload.txt')
    [IO.File]::WriteAllText($PayloadFile, "$Content`n", [Text.UTF8Encoding]::new($false))
    $PayloadHash = [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($PayloadFile))
    ).ToLowerInvariant()
    $PayloadPath = [IO.Path]::GetRelativePath($Repository, $PayloadFile).Replace('\', '/')
    [ordered]@{
        schemaVersion = '1.0'
        phaseId = $PhaseId
        attemptId = if ($AttemptId) { $AttemptId } else { [guid]::NewGuid().ToString() }
        outcome = 'Completed'
        expectedTasks = 1
        completedTasks = 1
        blockedReason = ''
        gatesSatisfied = $true
        payloadPath = $PayloadPath
        payloadSha256 = $PayloadHash
    } | ConvertTo-Json | Set-Content -LiteralPath $OutputFile -Encoding utf8NoBOM
}
exit $ExitCode
