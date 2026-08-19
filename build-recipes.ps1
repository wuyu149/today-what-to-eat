$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$jsonPath = Join-Path $projectRoot 'recipes.json'
$jsPath = Join-Path $projectRoot 'recipes.js'
$sourcesPath = Join-Path $projectRoot 'sources.json'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path -LiteralPath $jsonPath)) {
    throw "找不到唯一数据源: $jsonPath"
}

$jsonBytes = [IO.File]::ReadAllBytes($jsonPath)
$jsonText = $utf8NoBom.GetString($jsonBytes)
$recipes = $jsonText | ConvertFrom-Json

$sha256 = [Security.Cryptography.SHA256]::Create()
try {
    $hash = ([BitConverter]::ToString($sha256.ComputeHash($jsonBytes))).Replace('-', '').ToLowerInvariant()
}
finally {
    $sha256.Dispose()
}

$newline = "`n"
$jsText = "/* recipes.json SHA256: $hash */$newline" +
    "'use strict';$newline" +
    "window.RECIPE_SOURCE_SHA256 = '$hash';$newline" +
    "window.RECIPES = $jsonText;$newline"
[IO.File]::WriteAllText($jsPath, $jsText, $utf8NoBom)

$recipeSources = foreach ($recipe in $recipes) {
    [ordered]@{
        recipeId = $recipe.id
        recipeName = $recipe.name
        repository = $recipe.sourceRepo
        commitSha = $recipe.commitSha
        sourceFile = $recipe.sourceFile
        sourceUrl = $recipe.sourceUrl
        license = $recipe.license
        accessedAt = '2026-08-17'
        adaptation = $recipe.adaptation
    }
}

$foodSafetySources = @()
$foodSafetySources += [ordered]@{
    publisher = 'U.S. Centers for Disease Control and Prevention (CDC)'
    title = 'Preventing Food Poisoning'
    url = 'https://www.cdc.gov/food-safety/prevention/'
    accessedAt = '2026-08-17'
    usedFor = '洗手、清洁、食材分开处理、充分加热和及时冷藏'
}
$foodSafetySources += [ordered]@{
    publisher = 'FoodSafety.gov (U.S. government)'
    title = 'Cook to a Safe Minimum Internal Temperature'
    url = 'https://www.foodsafety.gov/food-safety-charts/safe-minimum-internal-temperatures'
    accessedAt = '2026-08-17'
    usedFor = '猪牛肉、肉末、鸡蛋和虾的安全熟成温度或状态'
}
$foodSafetySources += [ordered]@{
    publisher = 'U.S. Food and Drug Administration (FDA)'
    title = 'Ready-to-Eat Foods: The 2-Hour Rule'
    url = 'https://www.fda.gov/food/people-risk-foodborne-illness/ready-eat-foods-food-safety-moms-be'
    accessedAt = '2026-08-17'
    usedFor = '熟米饭和易腐熟食在两小时内冷藏'
}

$sources = [ordered]@{
    generatedFrom = 'recipes.json'
    sourceSha256 = $hash
    recipeSources = @($recipeSources)
    foodSafetySources = @($foodSafetySources)
}

$sourcesText = $sources | ConvertTo-Json -Depth 10
[IO.File]::WriteAllText($sourcesPath, $sourcesText + $newline, $utf8NoBom)

Write-Output "Generated recipes.js and sources.json"
Write-Output "recipes.json SHA256: $hash"
Write-Output "Recipe count: $($recipes.Count)"
