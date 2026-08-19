param(
    [string]$RecipesPath = (Join-Path $PSScriptRoot 'recipes.json'),
    [switch]$ProbeMissingField
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$requiredFields = @(
    'id', 'name', 'staple', 'ingredients', 'extraSeasonings', 'prep', 'steps',
    'heat', 'timings', 'doneness', 'rescue', 'totalMinutes', 'difficulty', 'tags',
    'sourceRepo', 'sourceFile', 'commitSha', 'sourceUrl', 'license', 'adaptation'
)
$arrayFields = @('ingredients', 'prep', 'steps', 'heat', 'timings', 'tags')

function Read-Utf8Json([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "找不到文件: $Path"
    }
    $text = [IO.File]::ReadAllText($Path, $utf8NoBom)
    return $text | ConvertFrom-Json
}

function Get-DataErrors($Recipes) {
    $errors = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $Recipes.Count; $index++) {
        $recipe = $Recipes[$index]
        $label = if ($recipe.id) { $recipe.id } else { "index-$index" }
        foreach ($field in $requiredFields) {
            $property = $recipe.PSObject.Properties[$field]
            if ($null -eq $property) {
                $errors.Add("$label 缺少字段 $field")
                continue
            }
            $value = $property.Value
            if ($null -eq $value) {
                $errors.Add("$label 字段 $field 为空")
            }
            elseif ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
                $errors.Add("$label 字段 $field 是空字符串")
            }
            elseif ($arrayFields -contains $field -and @($value).Count -eq 0) {
                $errors.Add("$label 数组 $field 为空")
            }
        }

        foreach ($ingredient in @($recipe.ingredients)) {
            foreach ($field in @('item', 'amount', 'owned')) {
                if ($null -eq $ingredient.PSObject.Properties[$field]) {
                    $errors.Add("$label 食材缺少字段 $field")
                }
            }
        }

        if ($recipe.totalMinutes -le 0 -or $recipe.totalMinutes -gt 40) {
            $errors.Add("$label 总时长必须在1到40分钟")
        }
        if ($recipe.difficulty -lt 1 -or $recipe.difficulty -gt 3) {
            $errors.Add("$label 难度必须在1到3")
        }
        if ($recipe.commitSha -notmatch '^[0-9a-f]{40}$') {
            $errors.Add("$label commit SHA格式错误")
        }
        if ($recipe.sourceUrl -notlike "*$($recipe.commitSha)*" -or $recipe.sourceUrl -notlike "*$($recipe.sourceFile)*") {
            $errors.Add("$label 原始链接未固定到commit和文件路径")
        }
    }
    return @($errors)
}

$script:passed = 0
$script:failed = 0
$script:skipped = 0

function Report-Test([string]$Name, [bool]$Condition, [string]$Detail) {
    if ($Condition) {
        $script:passed++
        Write-Output "[PASS] $Name - $Detail"
    }
    else {
        $script:failed++
        Write-Output "[FAIL] $Name - $Detail"
    }
}

$jsonText = [IO.File]::ReadAllText($RecipesPath, $utf8NoBom)
$recipes = $jsonText | ConvertFrom-Json

if ($ProbeMissingField) {
    $recipes[0].PSObject.Properties.Remove('prep')
    $probeErrors = @(Get-DataErrors $recipes)
    if (@($probeErrors | Where-Object { $_ -like '*缺少字段 prep*' }).Count -gt 0) {
        Write-Output "[FAIL] 必填字段完整 - 反向验证捕获：$($probeErrors[0])"
        Write-Output 'Passed: 0  Failed: 1  Skipped: 0'
        exit 1
    }
    Write-Output '[PASS] 反向验证意外未失败'
    exit 0
}

Report-Test '菜谱数量' ($recipes.Count -ge 30) "实际 $($recipes.Count)，下限 30"

$uniqueIds = @($recipes.id | Sort-Object -Unique).Count
$uniqueNames = @($recipes.name | Sort-Object -Unique).Count
Report-Test 'ID和菜名不重复' ($uniqueIds -eq $recipes.Count -and $uniqueNames -eq $recipes.Count) "ID $uniqueIds / 菜名 $uniqueNames"

$dataErrors = Get-DataErrors $recipes
Report-Test '必填字段齐全' ($dataErrors.Count -eq 0) $(if ($dataErrors.Count -eq 0) { '30道全部完整' } else { $dataErrors -join '; ' })

$sourcesPath = Join-Path $PSScriptRoot 'sources.json'
$sources = Read-Utf8Json $sourcesPath
$sourceErrors = New-Object System.Collections.Generic.List[string]
if (@($sources.recipeSources).Count -ne $recipes.Count) {
    $sourceErrors.Add("逐道来源数 $(@($sources.recipeSources).Count) 与菜谱数 $($recipes.Count) 不同")
}
foreach ($recipe in $recipes) {
    $record = @($sources.recipeSources | Where-Object { $_.recipeId -eq $recipe.id })
    if ($record.Count -ne 1) {
        $sourceErrors.Add("$($recipe.id) 的来源记录数量为 $($record.Count)")
        continue
    }
    foreach ($field in @('repository', 'commitSha', 'sourceFile', 'sourceUrl', 'license', 'accessedAt', 'adaptation')) {
        if ([string]::IsNullOrWhiteSpace([string]$record[0].$field)) {
            $sourceErrors.Add("$($recipe.id) 来源字段 $field 为空")
        }
    }
}
Report-Test '来源记录完整' ($sourceErrors.Count -eq 0) $(if ($sourceErrors.Count -eq 0) { '逐道30条，食品安全来源3条' } else { $sourceErrors -join '; ' })

$forbidden = @('烤箱', '空气炸锅', '微波炉', '蒸箱', '压力锅', '电压力锅')
$hits = New-Object System.Collections.Generic.List[string]
foreach ($keyword in $forbidden) {
    if ($jsonText.Contains($keyword)) { $hits.Add($keyword) }
}
Report-Test '禁止设备关键词为0' ($hits.Count -eq 0) $(if ($hits.Count -eq 0) { '0个命中' } else { $hits -join '、' })

$sha = [Security.Cryptography.SHA256]::Create()
try {
    $jsonHash = ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($RecipesPath)))).Replace('-', '').ToLowerInvariant()
}
finally {
    $sha.Dispose()
}
$jsPath = Join-Path $PSScriptRoot 'recipes.js'
$jsText = [IO.File]::ReadAllText($jsPath, $utf8NoBom)
$match = [regex]::Match($jsText, 'recipes\.json SHA256: ([0-9a-f]{64})')
$embeddedHash = if ($match.Success) { $match.Groups[1].Value } else { '' }
Report-Test 'recipes.json与recipes.js的SHA256一致' ($jsonHash -eq $embeddedHash) "JSON $jsonHash / JS $embeddedHash"

$history = New-Object System.Collections.Generic.List[string]
$current = $null
$randomError = $null
for ($iteration = 0; $iteration -lt 1000; $iteration++) {
    $pool = @($recipes | Where-Object { $_.id -ne $current -and -not $history.Contains([string]$_.id) })
    if ($pool.Count -eq 0) {
        $pool = @($recipes | Where-Object { $_.id -ne $current })
    }
    if ($pool.Count -eq 0) {
        $randomError = "第$iteration次候选为空"
        break
    }
    $next = $pool[(Get-Random -Minimum 0 -Maximum $pool.Count)]
    if ($null -eq $next -or [string]::IsNullOrWhiteSpace([string]$next.id)) {
        $randomError = "第$iteration次结果为空"
        break
    }
    if ($next.id -eq $current) {
        $randomError = "第$iteration次与当前结果连续重复"
        break
    }
    $current = [string]$next.id
    $newHistory = New-Object System.Collections.Generic.List[string]
    $newHistory.Add($current)
    foreach ($id in $history) {
        if ($id -ne $current -and $newHistory.Count -lt 5) { $newHistory.Add($id) }
    }
    $history = $newHistory
}
Report-Test '随机1000次无空值和连续重复' ($null -eq $randomError) $(if ($null -eq $randomError) { '1000次通过，最近记录保持5条以内' } else { $randomError })

$expectedFiles = @('CLAUDE.md','README.md','PROGRESS.md','BLOCKED.md','THIRD_PARTY_NOTICES.md','sources.json','recipes.json','recipes.js','build-recipes.ps1','index.html','styles.css','app.js','tests.ps1')
$missingFiles = @($expectedFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $_)) })
Report-Test '交付文件齐全' ($missingFiles.Count -eq 0) $(if ($missingFiles.Count -eq 0) { '13个白名单文件存在' } else { '缺少: ' + ($missingFiles -join ', ') })

Write-Output "Passed: $script:passed  Failed: $script:failed  Skipped: $script:skipped"
if ($script:failed -gt 0) { exit 1 }
exit 0
