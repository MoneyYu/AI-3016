#Requires -Version 7.0
<#
.SYNOPSIS
    下載 AI-3016 官方課程範例資料，並上傳到 backup 環境的 Storage Account。

.DESCRIPTION
    此腳本由 Terraform 的 terraform_data.sample_data 透過 local-exec 呼叫。

    刻意「即時下載官方檔案」而不是把二進位檔 commit 進 repo：
      * 資料永遠與現行 lab 一致，不會有 repo 內副本過期的問題
      * 不必處理 .gitattributes 的 binary 正規化風險

    需要已登入的 `az` session（Storage 停用了存取金鑰，只能用 Entra ID）。

.NOTES
    失敗一律 throw，不會靜默 exit 0。
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

function Invoke-Download {
    param(
        [Parameter(Mandatory)][string] $Uri,
        [Parameter(Mandatory)][string] $OutFile,
        [int] $MaxAttempts = 4
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -TimeoutSec 120
            if (-not (Test-Path -LiteralPath $OutFile)) {
                throw "下載後找不到檔案：$OutFile"
            }
            $size = (Get-Item -LiteralPath $OutFile).Length
            if ($size -le 0) {
                throw "下載的檔案是空的：$Uri"
            }
            Write-Host ("  下載完成 {0} ({1:N0} bytes)" -f (Split-Path -Leaf $OutFile), $size)
            return
        }
        catch {
            if ($attempt -eq $MaxAttempts) {
                throw "下載失敗（已重試 $MaxAttempts 次）：$Uri`n$($_.Exception.Message)"
            }
            $delay = [Math]::Pow(2, $attempt)
            Write-Warning "下載 $Uri 失敗（第 $attempt 次），$delay 秒後重試..."
            Start-Sleep -Seconds $delay
        }
    }
}

function Invoke-BlobUploadBatch {
    param(
        [Parameter(Mandatory)][string] $Account,
        [Parameter(Mandatory)][string] $Container,
        [Parameter(Mandatory)][string] $Source,
        [int] $MaxAttempts = 8
    )

    # Storage 的 RBAC 角色指派需要時間傳播，前幾次呼叫可能回 403。
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $output = az storage blob upload-batch `
            --account-name $Account `
            --destination $Container `
            --source $Source `
            --overwrite true `
            --auth-mode login `
            --only-show-errors 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  已上傳 $Source -> $Account/$Container"
            return
        }

        $text = ($output | Out-String)
        # az CLI 的權限錯誤訊息文字不固定（有時完全不含 401/403），
        # 因此比對範圍要夠寬，才不會把 RBAC 傳播延遲誤判為終端錯誤。
        $isAuth = $text -match 'AuthorizationPermissionMismatch|AuthorizationFailure|AuthenticationFailed|required permissions|not authorized|Forbidden|\b40[13]\b'

        if (-not $isAuth -or $attempt -eq $MaxAttempts) {
            throw "上傳到 $Account/$Container 失敗（第 $attempt 次）：`n$text"
        }

        $delay = 15 * $attempt
        Write-Warning "Storage RBAC 尚未生效（第 $attempt 次），$delay 秒後重試..."
        Start-Sleep -Seconds $delay
    }
}

# --- 讀取 Terraform 傳入的環境變數 -------------------------------------------
$storageAccount     = Get-RequiredEnv 'STORAGE_ACCOUNT'
$brochuresContainer = Get-RequiredEnv 'BROCHURES_CONTAINER'
$agentContainer     = Get-RequiredEnv 'AGENT_FILES_CONTAINER'
$finetuneContainer  = Get-RequiredEnv 'FINETUNE_CONTAINER'
$stagingPath        = Get-RequiredEnv 'STAGING_PATH'

# 官方來源（2026-08-20 全部驗證為 HTTP 200）
$brochuresZipUrl = 'https://github.com/MicrosoftLearning/mslearn-ai-studio/raw/main/data/brochures.zip'
$finetuneUrl     = 'https://microsoftlearning.github.io/mslearn-ai-studio/data/travel-finetune-hotel.jsonl'
$agentFileUrls   = @{
    'IT_Policy.txt'          = 'https://raw.githubusercontent.com/MicrosoftLearning/mslearn-ai-agents/main/Labfiles/01-build-agent-portal-and-vscode/IT_Policy.txt'
    'system_performance.csv' = 'https://raw.githubusercontent.com/MicrosoftLearning/mslearn-ai-agents/main/Labfiles/01-build-agent-portal-and-vscode/system_performance.csv'
}

$brochuresDir = Join-Path $stagingPath 'brochures'
$agentDir     = Join-Path $stagingPath 'agent-files'
$finetuneDir  = Join-Path $stagingPath 'finetune'

Write-Host "AI-3016 範例資料準備中..."
Write-Host "  暫存目錄: $stagingPath"

foreach ($dir in @($stagingPath, $brochuresDir, $agentDir, $finetuneDir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# --- 1. Margie's Travel 手冊（模組 4 的 file_search / vector store demo）------
Write-Host "[1/3] 下載 Margie's Travel 手冊..."
$zipPath = Join-Path $stagingPath 'brochures.zip'
Invoke-Download -Uri $brochuresZipUrl -OutFile $zipPath

Get-ChildItem -LiteralPath $brochuresDir -File -ErrorAction SilentlyContinue | Remove-Item -Force
Expand-Archive -LiteralPath $zipPath -DestinationPath $brochuresDir -Force

# 壓縮檔可能含有一層資料夾；把 PDF 全部攤平到 brochuresDir。
Get-ChildItem -LiteralPath $brochuresDir -Recurse -File -Filter '*.pdf' |
    Where-Object { $_.DirectoryName -ne $brochuresDir } |
    ForEach-Object { Move-Item -LiteralPath $_.FullName -Destination $brochuresDir -Force }
Get-ChildItem -LiteralPath $brochuresDir -Directory | Remove-Item -Recurse -Force

$pdfCount = (Get-ChildItem -LiteralPath $brochuresDir -File -Filter '*.pdf').Count
if ($pdfCount -lt 1) {
    throw "brochures.zip 解壓縮後找不到任何 PDF，無法建立模組 4 的 vector store。"
}
Write-Host "  取得 $pdfCount 份手冊 PDF"

# --- 2. 模組 7 agent 檔案 -----------------------------------------------------
Write-Host "[2/3] 下載模組 7 的 agent 檔案..."
foreach ($name in $agentFileUrls.Keys) {
    Invoke-Download -Uri $agentFileUrls[$name] -OutFile (Join-Path $agentDir $name)
}

# --- 3. 模組 5 微調訓練資料 ---------------------------------------------------
Write-Host "[3/3] 下載模組 5 的微調訓練資料..."
Invoke-Download -Uri $finetuneUrl -OutFile (Join-Path $finetuneDir 'travel-finetune-hotel.jsonl')

# --- 上傳到 Blob（講師方便取用；Entra ID 驗證）--------------------------------
Write-Host "上傳到 Storage Account '$storageAccount'..."
Invoke-BlobUploadBatch -Account $storageAccount -Container $brochuresContainer -Source $brochuresDir
Invoke-BlobUploadBatch -Account $storageAccount -Container $agentContainer     -Source $agentDir
Invoke-BlobUploadBatch -Account $storageAccount -Container $finetuneContainer  -Source $finetuneDir

Write-Host "範例資料準備完成。"