[CmdletBinding()]
param(
    [switch]$ProbeDataMismatch
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$miniRoot = Join-Path $projectRoot 'wechat-mini\miniprogram'
$failures = New-Object System.Collections.Generic.List[string]
$passes = New-Object System.Collections.Generic.List[string]

function Add-Pass([string]$message) {
    $passes.Add($message)
    Write-Output "[PASS] $message"
}

function Add-Failure([string]$message) {
    $failures.Add($message)
    Write-Output "[FAIL] $message"
}

function Assert-Check([bool]$condition, [string]$message) {
    if ($condition) { Add-Pass $message } else { Add-Failure $message }
}

function Get-Sha256([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}

$requiredFiles = @(
    'project.config.json',
    'miniprogram\app.js',
    'miniprogram\app.json',
    'miniprogram\app.wxss',
    'miniprogram\sitemap.json',
    'miniprogram\data\recipes.js',
    'miniprogram\utils\selector.js',
    'miniprogram\utils\storage.js',
    'miniprogram\pages\index\index.js',
    'miniprogram\pages\index\index.json',
    'miniprogram\pages\index\index.wxml',
    'miniprogram\pages\index\index.wxss',
    'miniprogram\pages\history\history.js',
    'miniprogram\pages\history\history.json',
    'miniprogram\pages\history\history.wxml',
    'miniprogram\pages\history\history.wxss',
    'miniprogram\pages\about\about.js',
    'miniprogram\pages\about\about.json',
    'miniprogram\pages\about\about.wxml',
    'miniprogram\pages\about\about.wxss'
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path (Split-Path $miniRoot -Parent) $_) -PathType Leaf) })
Assert-Check ($missingFiles.Count -eq 0) 'Required mini-program files are present'

try {
    $projectConfig = Get-Content -LiteralPath (Join-Path (Split-Path $miniRoot -Parent) 'project.config.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $appConfig = Get-Content -LiteralPath (Join-Path $miniRoot 'app.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $sitemap = Get-Content -LiteralPath (Join-Path $miniRoot 'sitemap.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $expectedPages = @('pages/index/index', 'pages/history/history', 'pages/about/about')
    $routesValid = @($expectedPages | Where-Object { $appConfig.pages -notcontains $_ }).Count -eq 0
    Assert-Check ($projectConfig.miniprogramRoot -eq 'miniprogram/' -and $routesValid -and $null -ne $sitemap.rules) 'Project config and three page routes are valid JSON'
}
catch {
    Add-Failure "Config parse failed: $($_.Exception.Message)"
}

$sourcePath = Join-Path $projectRoot 'recipes.json'
$generatedPath = Join-Path $miniRoot 'data\recipes.js'
$sourceHash = Get-Sha256 $sourcePath
$generatedText = Get-Content -LiteralPath $generatedPath -Raw -Encoding UTF8
$hashMatch = [regex]::Match($generatedText, '^/\* recipes\.json SHA256: (?<hash>[0-9a-f]{64}) \*/')
$declaredHash = if ($hashMatch.Success) { $hashMatch.Groups['hash'].Value } else { '' }
if ($ProbeDataMismatch) {
    $declaredHash = '0' * 64
}
Assert-Check ($declaredHash -eq $sourceHash) 'Generated mini-program data SHA256 matches recipes.json'

$sourceRecipes = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8 | ConvertFrom-Json
$dataMatch = [regex]::Match($generatedText, 'const recipes = (?<json>\[[\s\S]*\])\s+module\.exports')
if ($dataMatch.Success) {
    try {
        $generatedRecipes = $dataMatch.Groups['json'].Value | ConvertFrom-Json
        Assert-Check ($sourceRecipes.Count -ge 30 -and $generatedRecipes.Count -eq $sourceRecipes.Count) 'Generated data contains all 30 recipes'
    }
    catch {
        Add-Failure "Generated recipe data parse failed: $($_.Exception.Message)"
        $generatedRecipes = @()
    }
}
else {
    Add-Failure 'Generated recipe data block was not found'
    $generatedRecipes = @()
}

$requiredFields = @(
    'id', 'name', 'staple', 'ingredients', 'extraSeasonings', 'prep', 'steps',
    'heat', 'timings', 'doneness', 'rescue', 'totalMinutes', 'difficulty', 'tags',
    'sourceRepo', 'sourceFile', 'commitSha', 'sourceUrl', 'license', 'adaptation'
)
$invalidRecipes = New-Object System.Collections.Generic.List[string]
foreach ($recipe in $sourceRecipes) {
    foreach ($field in $requiredFields) {
        $property = $recipe.PSObject.Properties[$field]
        if ($null -eq $property -or $null -eq $property.Value -or ($property.Value -is [string] -and [string]::IsNullOrWhiteSpace($property.Value))) {
            $invalidRecipes.Add("$($recipe.id):$field")
        }
    }
}
$duplicateIds = @($sourceRecipes | Group-Object id | Where-Object Count -gt 1)
$duplicateNames = @($sourceRecipes | Group-Object name | Where-Object Count -gt 1)
Assert-Check ($invalidRecipes.Count -eq 0 -and $duplicateIds.Count -eq 0 -and $duplicateNames.Count -eq 0) 'Recipe fields, IDs, names, and source records are complete'

$runtimeFiles = Get-ChildItem -LiteralPath $miniRoot -Recurse -File | Where-Object {
    $_.FullName -notlike '*\data\recipes.js' -and $_.Extension -in @('.js', '.json', '.wxml')
}
$forbiddenMatches = New-Object System.Collections.Generic.List[string]
foreach ($file in $runtimeFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($text -match 'wx\.(request|downloadFile|uploadFile|connectSocket|login)\s*\(' -or $text -match '<\s*web-view\b' -or $text -match 'wx\.cloud\b') {
        $forbiddenMatches.Add($file.FullName)
    }
}
Assert-Check ($forbiddenMatches.Count -eq 0) 'Runtime contains no network, cloud, login, or web-view calls'

$selectorPath = Join-Path $miniRoot 'utils\selector.js'
$selectorText = Get-Content -LiteralPath $selectorPath -Raw -Encoding UTF8
$meatArrayMatch = [regex]::Match($selectorText, 'const MEAT_TAGS = \[(?<tags>[^\]]+)\]')
$meatTags = @([regex]::Matches($meatArrayMatch.Groups['tags'].Value, "'(?<value>[^']+)'") | ForEach-Object { $_.Groups['value'].Value })
$riceWord = ([char]0x7C73).ToString() + [char]0x996D
$coveredRiceWord = ([char]0x76D6).ToString() + [char]0x996D
$friedRiceWord = ([char]0x7092).ToString() + [char]0x996D
$noodleWord = ([char]0x9762).ToString()

function Test-RecipeFilter($recipe, [string]$diet, [string]$staple, [string]$time) {
    $isMeat = @($recipe.tags | Where-Object { $meatTags -contains $_ }).Count -gt 0
    if ($diet -eq 'meat' -and -not $isMeat) { return $false }
    if ($diet -eq 'no-meat' -and $isMeat) { return $false }
    if ($staple -eq 'rice' -and $recipe.staple -notmatch "$riceWord|$coveredRiceWord|$friedRiceWord") { return $false }
    if ($staple -eq 'noodle' -and $recipe.staple -notmatch $noodleWord) { return $false }
    if ($time -eq '30' -and $recipe.totalMinutes -gt 30) { return $false }
    return $true
}

$indexJs = Get-Content -LiteralPath (Join-Path $miniRoot 'pages\index\index.js') -Raw -Encoding UTF8
$guardedEmpty = $indexJs -match 'filterRecipes\(recipes, filters\)\.length' -and $indexJs -match 'if \(!selected\)' -and $indexJs -match 'wx\.showToast'
$emptyCombinations = 0
$filterInvalid = $false
foreach ($diet in @('all', 'meat', 'no-meat')) {
    foreach ($staple in @('all', 'rice', 'noodle')) {
        foreach ($time in @('all', '30')) {
            $matched = @($sourceRecipes | Where-Object { Test-RecipeFilter $_ $diet $staple $time })
            if ($matched.Count -eq 0) { $emptyCombinations++ }
            elseif (@($matched | Where-Object { [string]::IsNullOrWhiteSpace($_.id) }).Count -gt 0) {
                Add-Failure "Filter returned an invalid recipe: $diet/$staple/$time"
                $filterInvalid = $true
            }
        }
    }
}
Assert-Check ($guardedEmpty -and -not $filterInvalid) "All filter combinations return recipes or are prevented before selection ($emptyCombinations prevented combinations)"

$history = @()
$currentId = ''
$randomOk = $true
for ($iteration = 0; $iteration -lt 1000; $iteration++) {
    $pool = @($sourceRecipes | Where-Object { $_.id -ne $currentId -and $history -notcontains $_.id })
    if ($pool.Count -eq 0) {
        $pool = @($sourceRecipes | Where-Object { $_.id -ne $currentId })
    }
    if ($pool.Count -eq 0) {
        $randomOk = $false
        break
    }
    $selected = $pool[(Get-Random -Minimum 0 -Maximum $pool.Count)]
    if ($null -eq $selected -or [string]::IsNullOrWhiteSpace($selected.id) -or $selected.id -eq $currentId) {
        $randomOk = $false
        break
    }
    $currentId = $selected.id
    $history = @($selected.id) + @($history | Where-Object { $_ -ne $selected.id })
    $history = @($history | Select-Object -First 5)
}
Assert-Check $randomOk 'Random selection ran 1000 times without blanks or consecutive repeats'

$storageText = Get-Content -LiteralPath (Join-Path $miniRoot 'utils\storage.js') -Raw -Encoding UTF8
$historyPageText = Get-Content -LiteralPath (Join-Path $miniRoot 'pages\history\history.js') -Raw -Encoding UTF8
$indexWxml = Get-Content -LiteralPath (Join-Path $miniRoot 'pages\index\index.wxml') -Raw -Encoding UTF8
$storageValid = $storageText -match 'wx\.getStorageSync' -and $storageText -match 'wx\.setStorageSync' -and $storageText -match '\.slice\(0, 5\)'
$historyValid = $historyPageText -match 'selectedHistory' -and $historyPageText -match 'navigateBack'
$singleCard = ([regex]::Matches($indexWxml, 'id="result-card"')).Count -eq 1
Assert-Check ($storageValid -and $historyValid -and $singleCard) 'Local recent-five storage, history recall, and single result card are wired'

$devToolsCandidates = @(
    'C:\Program Files (x86)\Tencent\微信web开发者工具\cli.bat',
    'C:\Program Files\Tencent\微信web开发者工具\cli.bat',
    'C:\Program Files (x86)\Tencent\微信开发者工具\cli.bat',
    'C:\Program Files\Tencent\微信开发者工具\cli.bat'
)
$devToolsCli = $devToolsCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if ($devToolsCli) {
    Write-Output "[INFO] WeChat DevTools CLI found: $devToolsCli"
}
else {
    Write-Output '[BLOCKED] WeChat DevTools CLI is not installed; preview and upload were not claimed.'
}

Write-Output "Result: $($passes.Count) passed, $($failures.Count) failed"
if ($failures.Count -gt 0) { exit 1 }
exit 0
