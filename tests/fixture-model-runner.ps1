#Requires -Version 7.0
[CmdletBinding()]
param(
    [string] $OutputFile = '',
    [string] $Content = 'fixture',
    [int] $ExitCode = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not [string]::IsNullOrWhiteSpace($OutputFile)) {
    Set-Content -LiteralPath $OutputFile -Value $Content -Encoding utf8NoBOM
}
exit $ExitCode
