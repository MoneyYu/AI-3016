#Requires -Version 7.0
<#
.SYNOPSIS
    AI-3016 backup 環境的模型可用性預檢閘門（terraform apply 之前務必先跑）。

.DESCRIPTION
    為什麼需要這支腳本：

    Microsoft 的兩份官方文件在此議題上互相矛盾——
      * 退役排程把 gpt-5 / gpt-5-mini 標為 GA；
      * 生命週期政策卻寫明「模型上市滿 12 個月後，新客戶無法建立部署」，
        而且「既有客戶」是以「訂閱」為單位判定，同租用戶的新訂閱不繼承。
      gpt-5 / gpt-5-mini 於 2025-08-07 上市，已在 2026-08-07 跨過該門檻。

    因此「能不能部署」不能用日期推算，必須對「實際要用的那個訂閱」實測。
    Skillable 學員訂閱與講師 demo 訂閱是不同訂閱，結果可能不同——兩邊都要跑。

.PARAMETER Location
    要檢查的區域，預設 swedencentral（本課的區域決策，見 docs/demo-environment.md）。

.PARAMETER ModelProfile
    parity  = lab 指定的模型（gpt-5.2 + gpt-5-mini）
    current = 較新的 GA 替代（gpt-5.4 + gpt-5.4-mini）

.PARAMETER RequiredCapacity
    每個模型需要的容量（單位：千 TPM），用來檢查剩餘配額是否足夠。

.EXAMPLE
    ./Test-ModelAvailability.ps1
    ./Test-ModelAvailability.ps1 -ModelProfile current -Location northcentralus
#>

[CmdletBinding()]
param(
    [string] $Location = 'swedencentral',

    [ValidateSet('parity', 'current')]
    [string] $ModelProfile = 'parity',

    [int] $RequiredCapacity = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$profiles = @{
    parity  = @('gpt-5.2', 'gpt-5-mini')
    current = @('gpt-5.4', 'gpt-5.4-mini')
}

# 微調基底：唯一同時滿足 SFT + 未 Deprecated + swedencentral 標準區域 +
# 支援 Developer 部署型別的模型。詳見 docs/demo-environment.md。
$finetuneBase = 'gpt-4.1-mini'

$requiredModels = @($profiles[$ModelProfile]) + @($finetuneBase)

$account = az account show -o json 2>$null | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or -not $account) {
    throw '找不到已登入的 az session。請先執行 az login。'
}

Write-Host '=== AI-3016 模型可用性預檢 ==='
Write-Host ("訂閱     : {0} ({1})" -f $account.name, $account.id)
Write-Host ("區域     : {0}" -f $Location)
Write-Host ("Profile  : {0} -> {1}" -f $ModelProfile, ($requiredModels -join ', '))
Write-Host ("查核時間 : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ''

$catalog = az cognitiveservices model list -l $Location -o json 2>$null | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or -not $catalog) {
    throw "無法列出 $Location 的模型型錄。請確認區域名稱與訂閱權限。"
}

$usage = az cognitiveservices usage list -l $Location -o json 2>$null | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    throw "無法讀取 $Location 的配額使用量。"
}

# 配額鍵名與模型名不完全一致：gpt-4.1 系列在配額中是 gpt4.1（沒有第一個點）。
function Get-QuotaKeyName {
    param([Parameter(Mandatory)][string] $ModelName)

    if ($ModelName -like 'gpt-4.1*') {
        return $ModelName -replace '^gpt-4\.1', 'gpt4.1'
    }
    return $ModelName
}

$failures = @()

foreach ($model in $requiredModels) {
    $entries = @($catalog | Where-Object { $_.model.name -eq $model -and $_.kind -eq 'AIServices' })

    if ($entries.Count -eq 0) {
        $failures += "$model : 型錄中找不到（kind=AIServices）。可能已 Deprecated 且本訂閱從未部署過該版本。"
        Write-Host ("[FAIL] {0,-14} 型錄中找不到" -f $model)
        continue
    }

    $entry = $entries[0]
    $skus = @($entry.model.skus | ForEach-Object { $_.name } | Select-Object -Unique)

    if ('GlobalStandard' -notin $skus) {
        $failures += "$model : 沒有 GlobalStandard SKU（可用：$($skus -join ', ')）。"
        Write-Host ("[FAIL] {0,-14} 無 GlobalStandard SKU" -f $model)
        continue
    }

    $quotaKey = 'OpenAI.GlobalStandard.' + (Get-QuotaKeyName $model)
    $quota = $usage | Where-Object { $_.name.value -eq $quotaKey } | Select-Object -First 1

    if (-not $quota) {
        $failures += "$model : 找不到配額項目 '$quotaKey'，代表本訂閱在 $Location 沒有該模型的標準配額。"
        Write-Host ("[FAIL] {0,-14} 無配額項目 {1}" -f $model, $quotaKey)
        continue
    }

    $free = [int] $quota.limit - [int] $quota.currentValue
    if ($free -lt $RequiredCapacity) {
        $failures += "$model : 配額不足（剩餘 $free，需要 $RequiredCapacity）。"
        Write-Host ("[FAIL] {0,-14} ver={1,-12} 配額剩餘 {2}（需要 {3}）" -f $model, $entry.model.version, $free, $RequiredCapacity)
        continue
    }

    Write-Host ("[ OK ] {0,-14} ver={1,-12} 配額剩餘 {2}" -f $model, $entry.model.version, $free)
}

# 微調後的模型會部署到 Developer tier，需要另一組配額。
$ftQuotaKey = 'OpenAI.DeveloperTier.' + (Get-QuotaKeyName $finetuneBase) + '-finetune'
$ftQuota = $usage | Where-Object { $_.name.value -eq $ftQuotaKey } | Select-Object -First 1

if (-not $ftQuota) {
    $failures += "微調部署 : 找不到配額項目 '$ftQuotaKey'，$finetuneBase 的微調模型無法部署到 Developer tier。"
    Write-Host ("[FAIL] {0,-14} 無配額項目 {1}" -f 'finetune', $ftQuotaKey)
}
else {
    $ftFree = [int] $ftQuota.limit - [int] $ftQuota.currentValue
    if ($ftFree -le 0) {
        $failures += "微調部署 : Developer tier 配額已用盡（$ftQuotaKey）。"
        Write-Host ("[FAIL] {0,-14} Developer tier 配額已用盡" -f 'finetune')
    }
    else {
        Write-Host ("[ OK ] {0,-14} {1} 配額剩餘 {2}" -f 'finetune', $ftQuotaKey, $ftFree)
    }
}

Write-Host ''

if ($failures.Count -gt 0) {
    Write-Host '=== 預檢失敗 ==='
    $failures | ForEach-Object { Write-Host "  - $_" }
    Write-Host ''
    if ($ModelProfile -eq 'parity') {
        Write-Host '建議：改用 current profile 再跑一次：'
        Write-Host '  ./Test-ModelAvailability.ps1 -ModelProfile current'
        Write-Host '若 current 通過，terraform apply 時加上 -var model_profile=current。'
    }
    throw "$Location 的模型預檢失敗，共 $($failures.Count) 項。請勿在此訂閱／區域執行 terraform apply。"
}

Write-Host '=== 預檢通過：可以執行 terraform apply ==='
Write-Host ("  terraform apply -var group_postfix=<MMDD> -var model_profile={0}" -f $ModelProfile)