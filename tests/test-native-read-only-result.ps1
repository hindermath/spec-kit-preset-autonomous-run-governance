#Requires -Version 7.3
<#
.SYNOPSIS
    DE: Prueft Host-Ergebnistransport fuer native lesende Profile.
    EN: Tests host result transport for native read-only profiles.
.DESCRIPTION
    DE: Verwendet die echten Runner-Funktionen ohne Modellaufruf.
    EN: Uses actual runner functions without model calls.
.EXAMPLE
    pwsh -NoProfile -File tests/test-native-read-only-result.ps1
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$runner=Join-Path $PSScriptRoot '../scripts/invoke-autonomous-model-phase.ps1'
$tokens=$null;$parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
foreach($name in @('Assert-AMRCondition','Write-AMRJsonAtomic','Write-AMRNativeReadOnlyResult')){
    $functionAst=$ast.Find({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true)
    . ([scriptblock]::Create($functionAst.Extent.Text))
}
$temporary=Join-Path ([IO.Path]::GetTempPath()) "native-readonly-result-$([guid]::NewGuid().ToString('N'))"
[void](New-Item -ItemType Directory $temporary)
try{
    $path=Join-Path $temporary 'result.json'
    Write-AMRNativeReadOnlyResult -Output @('{"outcome":"Completed","phaseId":"fixture"}') -Path $path
    if((Get-Content $path -Raw|ConvertFrom-Json).outcome -cne 'Completed'){throw 'Host did not persist JSON.'}
    $hash=(Get-FileHash $path).Hash
    foreach($bad in @('not-json','[]','{"outcome":"Completed"} trailing prose')){
        $rejected=$false
        try{Write-AMRNativeReadOnlyResult -Output @($bad) -Path $path}catch{$rejected=$true}
        if(-not $rejected -or (Get-FileHash $path).Hash -cne $hash){throw 'Invalid result did not fail closed.'}
    }
    'PASS: native read-only JSON persisted by host; invalid output preserves prior result.'
}finally{Remove-Item -LiteralPath $temporary -Recurse -Force}
