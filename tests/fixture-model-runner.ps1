#Requires -Version 7.0
[CmdletBinding()]
param(
    [string] $OutputFile = '',
    [string] $PhaseId = 'fixture',
    [string] $Content = 'fixture',
    [int] $ExitCode = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
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
        attemptId = [guid]::NewGuid().ToString()
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
