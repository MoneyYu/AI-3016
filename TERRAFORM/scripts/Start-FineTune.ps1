#Requires -Version 7.0
<#
.SYNOPSIS
    模組 5 的微調示範：對 gpt-4.1-mini 執行監督式微調（SFT）。

.DESCRIPTION
    刻意「不」放進 terraform apply：微調通常要 60 分鐘以上，上課當場來不及。
    請在**開課前 1-2 天**手動執行本腳本。

    為什麼不是 lab 寫的 gpt-5：
      Lab 04b 要求在 gpt-5 上做 Supervised 微調，但官方微調支援表
      （models-sold-directly-by-azure#fine-tuning-models）列出 gpt-5 只支援
      RFT，且註明「gated and available by invitation only」。
      gpt-4.1-mini 是唯一同時滿足以下條件的模型：
        * 支援 SFT 且狀態為 GA
        * 基底不是 Deprecated（是 Legacy，仍可建立新部署）
        * 在 swedencentral 屬於微調「標準區域」
        * 支援 Developer 部署型別（lab 指定的部署型別）
      注意：整個 gpt-4.1 系列在 2027-04-14 退役，每次開課前都要重新確認。

.PARAMETER Endpoint
    Azure OpenAI v1 端點，例如 https://<name>.openai.azure.com/openai/v1
    （可由 terraform output azure_openai_v1_endpoint 取得）

.PARAMETER TrainingFile
    訓練資料 JSONL。預設會即時下載官方的 travel-finetune-hotel.jsonl。

.PARAMETER Deploy
    微調完成後，自動把結果部署到 Developer tier（等同 lab 的
    「Automatically deploy model after job completion」）。需要 -ResourceGroup 與 -AccountName。

.EXAMPLE
    ./Start-FineTune.ps1 -Endpoint (terraform output -raw azure_openai_v1_endpoint) `
                         -ResourceGroup AI3016-0821 -AccountName ai3016-0821-foundry-gen -Deploy
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Endpoint,
    [string] $TrainingFile,
    [string] $BaseModel = 'gpt-4.1-mini',
    [string] $Suffix = 'ft-travel',
    [switch] $Deploy,
    [string] $ResourceGroup,
    [string] $AccountName,
    [int] $DeployCapacity = 1,
    [int] $TimeoutMinutes = 180
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Endpoint = $Endpoint.TrimEnd('/')

function Get-AadToken {
    foreach ($resource in @('https://ai.azure.com', 'https://cognitiveservices.azure.com')) {
        $token = az account get-access-token --resource $resource --query accessToken -o tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($token)) {
            return $token.Trim()
        }
    }
    throw ' 無法取得 Entra ID access token。請先執行 az login。'
}

function Invoke-OpenAIApi {
    param(
        [Parameter(Mandatory)][string] $Method,
        [Parameter(Mandatory)][string] $Path,
        [object] $Body,
        [hashtable] $Form,
        [int] $MaxAttempts = 8
    )

    $uri = "$Endpoint$Path"

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $headers = @{ Authorization = "Bearer $(Get-AadToken)" }

        try {
            if ($Form) {
                return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Form $Form -TimeoutSec 600
            }
            if ($null -ne $Body) {
                $json = $Body | ConvertTo-Json -Depth 12 -Compress
                return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' -Body $json -TimeoutSec 600
            }
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -TimeoutSec 600
        }
        catch {
            $status = $null
            if ($_.Exception.PSObject.Properties.Name -contains 'Response' -and $_.Exception.Response) {
                $status = [int] $_.Exception.Response.StatusCode
            }

            $retryable = $status -in @(401, 403, 408, 429, 500, 502, 503, 504)
            if (-not $retryable -or $attempt -eq $MaxAttempts) {
                throw "$Method $uri 失敗（HTTP $status，第 $attempt 次）：$($_.Exception.Message)"
            }

            $delay = [Math]::Min(60, 8 * $attempt)
            Write-Warning "$Method $uri 回傳 HTTP $status（第 $attempt 次），$delay 秒後重試..."
            Start-Sleep -Seconds $delay
        }
    }
}

# --- 準備訓練資料 ------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($TrainingFile)) {
    $TrainingFile = Join-Path ([IO.Path]::GetTempPath()) 'travel-finetune-hotel.jsonl'
    $url = 'https://microsoftlearning.github.io/mslearn-ai-studio/data/travel-finetune-hotel.jsonl'
    Write-Host "下載官方訓練資料：$url"
    Invoke-WebRequest -Uri $url -OutFile $TrainingFile -UseBasicParsing -TimeoutSec 120
}

if (-not (Test-Path -LiteralPath $TrainingFile)) {
    throw "找不到訓練資料 '$TrainingFile'。"
}

$lineCount = (Get-Content -LiteralPath $TrainingFile | Where-Object { $_.Trim() }).Count
if ($lineCount -lt 10) {
    throw "訓練資料只有 $lineCount 筆；微調工作至少需要 10 筆範例。"
}

Write-Host '=== AI-3016 模組 5 微調 ==='
Write-Host "  端點     : $Endpoint"
Write-Host "  基底模型 : $BaseModel"
Write-Host "  訓練資料 : $TrainingFile（$lineCount 筆）"
Write-Host ''

# --- 上傳訓練檔 --------------------------------------------------------------
$uploaded = Invoke-OpenAIApi -Method POST -Path '/files' -Form @{
    purpose = 'fine-tune'
    file    = Get-Item -LiteralPath $TrainingFile
}
if (-not $uploaded.id) {
    throw '上傳訓練資料失敗：回應沒有 id。'
}
Write-Host "訓練檔已上傳：$($uploaded.id)"

# 等待檔案處理完成
$fileTimeout = [TimeSpan]::FromMinutes(15)
$fileSw = [Diagnostics.Stopwatch]::StartNew()
while ($true) {
    $fileState = Invoke-OpenAIApi -Method GET -Path "/files/$($uploaded.id)"
    if ($fileState.status -eq 'processed') { break }
    if ($fileState.status -eq 'error') {
        throw "訓練檔處理失敗：$($fileState.status_details)"
    }
    if ($fileSw.Elapsed -gt $fileTimeout) {
        throw "等待訓練檔處理逾時（$($fileTimeout.TotalMinutes) 分鐘），最後狀態 $($fileState.status)。"
    }
    Write-Host "  檔案狀態 $($fileState.status)..."
    Start-Sleep -Seconds 10
}

# --- 建立微調工作 ------------------------------------------------------------
$job = Invoke-OpenAIApi -Method POST -Path '/fine_tuning/jobs' -Body @{
    model         = $BaseModel
    training_file = $uploaded.id
    suffix        = $Suffix
    method        = @{ type = 'supervised' }
}
if (-not $job.id) {
    throw '建立微調工作失敗：回應沒有 id。'
}
Write-Host "微調工作已建立：$($job.id)"
Write-Host '（通常需要 60 分鐘以上，請耐心等待）'

# --- 輪詢直到完成（逾時必 throw）--------------------------------------------
$timeout = [TimeSpan]::FromMinutes($TimeoutMinutes)
$sw = [Diagnostics.Stopwatch]::StartNew()
$lastStatus = ''

while ($true) {
    $state = Invoke-OpenAIApi -Method GET -Path "/fine_tuning/jobs/$($job.id)"

    if ($state.status -ne $lastStatus) {
        Write-Host ("  [{0:hh\:mm\:ss}] 狀態 {1}" -f $sw.Elapsed, $state.status)
        $lastStatus = $state.status
    }

    if ($state.status -eq 'succeeded') {
        break
    }
    if ($state.status -in @('failed', 'cancelled')) {
        $detail = $state.error | ConvertTo-Json -Depth 5 -Compress
        throw "微調工作 $($job.id) 結束於狀態 '$($state.status)'：$detail"
    }
    if ($sw.Elapsed -gt $timeout) {
        throw "微調工作 $($job.id) 逾時（$TimeoutMinutes 分鐘），最後狀態 '$($state.status)'。"
    }

    Start-Sleep -Seconds 60
}

$fineTunedModel = $state.fine_tuned_model
if ([string]::IsNullOrWhiteSpace($fineTunedModel)) {
    throw "微調工作 $($job.id) 顯示成功，但沒有回傳 fine_tuned_model 名稱。"
}

Write-Host ''
Write-Host "微調完成：$fineTunedModel"

# --- 部署到 Developer tier ---------------------------------------------------
if ($Deploy) {
    if ([string]::IsNullOrWhiteSpace($ResourceGroup) -or [string]::IsNullOrWhiteSpace($AccountName)) {
        throw '使用 -Deploy 時必須同時提供 -ResourceGroup 與 -AccountName。'
    }

    $deploymentName = "$BaseModel-$Suffix"
    Write-Host "部署微調後的模型為 '$deploymentName'（Developer tier）..."

    az cognitiveservices account deployment create `
        --resource-group $ResourceGroup `
        --name $AccountName `
        --deployment-name $deploymentName `
        --model-name $fineTunedModel `
        --model-version '1' `
        --model-format OpenAI `
        --sku-name DeveloperTier `
        --sku-capacity $DeployCapacity `
        --only-show-errors | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "部署微調模型 '$fineTunedModel' 失敗。請確認 Developer tier 配額（OpenAI.DeveloperTier.gpt4.1-mini-finetune）。"
    }

    Write-Host "部署完成：$deploymentName"
}
else {
    Write-Host '（未指定 -Deploy，請在 Foundry portal 手動部署，或重新執行本腳本並加上 -Deploy）'
}

Write-Host ''
Write-Host '=== 微調示範就緒 ==='
Write-Host "  基底部署   : $BaseModel"
Write-Host "  微調後模型 : $fineTunedModel"