#Requires -Version 7.0
<#
.SYNOPSIS
    建立預先載入 Margie's Travel 手冊的 vector store（模組 4 file_search demo 的保底）。

.DESCRIPTION
    由 Terraform 的 terraform_data.vector_store 透過 local-exec 呼叫。

    模組 4 的 lab 程式碼會自己建立 vector store，但那需要時間；此腳本先建好一份
    「已就緒」的 vector store，讓講師在 live demo 失敗時可以立刻切換使用。

    使用 Azure OpenAI v1 資料平面 API 與 Entra ID bearer token（帳戶停用金鑰）。

.NOTES
    * 401/403 會重試以吸收 RBAC 傳播延遲。
    * 輪詢逾時或終端錯誤一律 throw，不會靜默 exit 0。
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RequiredEnv {
    param([Parameter(Mandatory)][string] $Name)

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "必要的環境變數 '$Name' 未設定。請確認 MOD.tf 的 environment 對應到本腳本的 Get-RequiredEnv 呼叫。"
    }
    return $value
}

function Get-AadToken {
    # Foundry / Azure OpenAI 資料平面的 token audience。先試新的 ai.azure.com，
    # 失敗再退回舊的 cognitiveservices.azure.com。
    foreach ($resource in @('https://ai.azure.com', 'https://cognitiveservices.azure.com')) {
        $token = az account get-access-token --resource $resource --query accessToken -o tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($token)) {
            return $token.Trim()
        }
    }
    throw "無法取得 Entra ID access token。請先執行 `az login`。"
}

function Invoke-OpenAIApi {
    param(
        [Parameter(Mandatory)][string] $Method,
        [Parameter(Mandatory)][string] $Uri,
        [object] $Body,
        [hashtable] $Form,
        [int] $MaxAttempts = 8
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $headers = @{ Authorization = "Bearer $(Get-AadToken)" }

        try {
            if ($Form) {
                return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Form $Form -TimeoutSec 300
            }
            if ($null -ne $Body) {
                $json = $Body | ConvertTo-Json -Depth 12 -Compress
                return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers `
                    -ContentType 'application/json' -Body $json -TimeoutSec 300
            }
            return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -TimeoutSec 300
        }
        catch {
            $status = $null
            if ($_.Exception.PSObject.Properties.Name -contains 'Response' -and $_.Exception.Response) {
                $status = [int] $_.Exception.Response.StatusCode
            }

            $retryable = $status -in @(401, 403, 408, 429, 500, 502, 503, 504)
            if (-not $retryable -or $attempt -eq $MaxAttempts) {
                throw "$Method $Uri 失敗（HTTP $status，第 $attempt 次）：$($_.Exception.Message)"
            }

            $delay = [Math]::Min(60, 8 * $attempt)
            Write-Warning "$Method $Uri 回傳 HTTP $status（第 $attempt 次），$delay 秒後重試（可能是 RBAC 尚未傳播）..."
            Start-Sleep -Seconds $delay
        }
    }
}

# --- 讀取 Terraform 傳入的環境變數 -------------------------------------------
$endpoint        = (Get-RequiredEnv 'OPENAI_V1_ENDPOINT').TrimEnd('/')
$vectorStoreName = Get-RequiredEnv 'VECTOR_STORE_NAME'
$brochuresPath   = Get-RequiredEnv 'BROCHURES_PATH'

if (-not (Test-Path -LiteralPath $brochuresPath)) {
    throw "找不到手冊目錄 '$brochuresPath'。請先成功執行 Get-SampleData.ps1。"
}

$pdfs = @(Get-ChildItem -LiteralPath $brochuresPath -File -Filter '*.pdf')
if ($pdfs.Count -lt 1) {
    throw "'$brochuresPath' 內沒有任何 PDF，無法建立 vector store。"
}

Write-Host "建立模組 4 的 demo vector store..."
Write-Host "  端點     : $endpoint"
Write-Host "  名稱     : $vectorStoreName"
Write-Host "  手冊份數 : $($pdfs.Count)"

# --- 清掉同名的舊 vector store（讓腳本可重複執行）----------------------------
$existing = Invoke-OpenAIApi -Method GET -Uri "$endpoint/vector_stores"
if ($existing -and $existing.PSObject.Properties.Name -contains 'data') {
    foreach ($store in @($existing.data | Where-Object { $_.name -eq $vectorStoreName })) {
        Write-Host "  移除同名的舊 vector store $($store.id)"
        Invoke-OpenAIApi -Method DELETE -Uri "$endpoint/vector_stores/$($store.id)" | Out-Null
    }
}

# --- 上傳手冊 ----------------------------------------------------------------
$fileIds = @()
foreach ($pdf in $pdfs) {
    $uploaded = Invoke-OpenAIApi -Method POST -Uri "$endpoint/files" -Form @{
        purpose = 'assistants'
        file    = Get-Item -LiteralPath $pdf.FullName
    }
    if (-not $uploaded.id) {
        throw "上傳 $($pdf.Name) 後沒有取得 file id。"
    }
    Write-Host "  已上傳 $($pdf.Name) -> $($uploaded.id)"
    $fileIds += $uploaded.id
}

# --- 建立 vector store -------------------------------------------------------
$store = Invoke-OpenAIApi -Method POST -Uri "$endpoint/vector_stores" -Body @{
    name     = $vectorStoreName
    file_ids = $fileIds
}
if (-not $store.id) {
    throw "建立 vector store 失敗：回應沒有 id。"
}
Write-Host "  vector store 已建立：$($store.id)"

# --- 等待索引完成（逾時必 throw）--------------------------------------------
$timeout = [TimeSpan]::FromMinutes(15)
$sw = [Diagnostics.Stopwatch]::StartNew()

while ($true) {
    $state = Invoke-OpenAIApi -Method GET -Uri "$endpoint/vector_stores/$($store.id)"
    $counts = $state.file_counts

    Write-Host ("  狀態 {0}｜completed={1} in_progress={2} failed={3}" -f `
        $state.status, $counts.completed, $counts.in_progress, $counts.failed)

    if ($counts.failed -gt 0) {
        throw "vector store $($store.id) 有 $($counts.failed) 個檔案索引失敗。"
    }
    if ($state.status -eq 'completed' -and $counts.completed -eq $fileIds.Count) {
        break
    }
    if ($state.status -eq 'expired') {
        throw "vector store $($store.id) 已過期，無法作為 demo 保底。"
    }
    if ($sw.Elapsed -gt $timeout) {
        throw "等待 vector store $($store.id) 索引完成逾時（$($timeout.TotalMinutes) 分鐘）。"
    }

    Start-Sleep -Seconds 10
}

Write-Host "vector store 就緒：$($store.id)（$($fileIds.Count) 份文件）"

# 把 id 寫到暫存目錄，讓 demo 程式與 New-DemoAgent.ps1 可以取用。
$stateFile = Join-Path (Split-Path -Parent $brochuresPath) 'demo-state.json'
$state = @{}
if (Test-Path -LiteralPath $stateFile) {
    $state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json -AsHashtable
}
$state['vector_store_id']   = $store.id
$state['vector_store_name'] = $vectorStoreName
$state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateFile -Encoding UTF8
Write-Host "  已寫入 $stateFile"