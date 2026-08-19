[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourcePath = Join-Path $projectRoot 'recipes.json'
$outputPath = Join-Path $projectRoot 'wechat-mini\miniprogram\data\recipes.js'

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Missing source file: $sourcePath"
}

$sourceBytes = [System.IO.File]::ReadAllBytes($sourcePath)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $hash = ([System.BitConverter]::ToString($sha256.ComputeHash($sourceBytes))).Replace('-', '').ToLowerInvariant()
}
finally {
    $sha256.Dispose()
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$json = $utf8.GetString($sourceBytes)
if ($json.Length -gt 0 -and $json[0] -eq [char]0xFEFF) {
    $json = $json.Substring(1)
}

$recipes = $json | ConvertFrom-Json
if (-not $recipes -or $recipes.Count -lt 1) {
    throw 'recipes.json contains no recipes.'
}

$outputDirectory = Split-Path -Parent $outputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}

$content = @"
/* recipes.json SHA256: $hash */
/* Generated from recipes.json. Do not edit manually. */
'use strict'

const sourceSha256 = '$hash'
const recipes = $json

module.exports = { recipes, sourceSha256 }
"@

[System.IO.File]::WriteAllText($outputPath, $content, $utf8)
Write-Output "Generated $outputPath"
Write-Output "Recipes: $($recipes.Count)"
Write-Output "SHA256: $hash"
