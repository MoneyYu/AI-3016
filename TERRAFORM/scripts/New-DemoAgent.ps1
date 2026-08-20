#Requires -Version 7.0
<#
.SYNOPSIS
    建立模組 7 的預備 demo agent（file_search + code_interpreter）。

.DESCRIPTION
    由 Terraform 的 terraform_data.demo_agent 透過 local-exec 呼叫，
    可用 var.enable_demo_agent = false 關閉。

    對應 mslearn-ai-agents 的 01-build-agent-portal-and-vscode 練習：
    建立一個 agent，掛上 IT_Policy.txt（file search）與
    system_performance.csv（code interpreter）。

    重要：agent 與其檔案可以預先建立並持久保存，但「對話」與
    Code Interpreter 的執行 session 無法保溫。上課當天仍需重開一個
    session 做 smoke test。

.NOTES
    * 401/403 會重試以吸收 RBAC 傳播延遲。
    * 若 Agent API 介面不同而回傳 404，會 throw 並提示改用 portal 手動建立。
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
    foreach ($resource in @('https://ai.azure.com', 'https://cognitiveservices.azure.com')) {
        $token = az account get-access-token --resource $resource --query accessToken -o tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($token)) {
            return $token.Trim()
        }
    }
    throw ' 無法取得 Entra ID access token。請先執行 az login。'
}

function Invoke-ProjectApi {
    param(
        [Parameter(Mandatory)][string] $Method,
        [Parameter(Mandatory)][string] $Path,
        [object] $Body,
        [hashtable] $Form,
        [int] $MaxAttempts = 8
    )

    $uri = "$script:ProjectEndpoint$Path"
    $separator = $uri.Contains('?') ? '&' : '?'
    $uri = "$uri$separator" + "api-version=$script:ApiVersion"

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $headers = @{ Authorization = "Bearer $(Get-AadToken)" }

        try {
            if ($Form) {
                return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Form $Form -TimeoutSec 300
            }
            if ($null -ne $Body) {
                $json = $Body | ConvertTo-Json -Depth 12 -Compress
                return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType 'application/json' -Body $json -TimeoutSec 300
            }
            return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -TimeoutSec 300
        }
        catch {
            $status = $null
            if ($_.Exception.PSObject.Properties.Name -contains 'Response' -and $_.Exception.Response) {
                $status = [int] $_.Exception.Response.StatusCode
            }

            if ($status -eq 404) {
                $hint = @(
                    "$Method $uri 回傳 HTTP 404。",
                    'Foundry Agent Service 的 REST 介面可能已變更。請改為在 Foundry portal 手動建立 demo agent：',
                    '  1. 開啟 https://ai.azure.com 並選擇本專案',
                    '  2. Agents -> Create agent',
                    '  3. 掛上 File search（上傳 IT_Policy.txt）與 Code interpreter（上傳 system_performance.csv）',
                    '或先設定 var.enable_demo_agent = false 讓 terraform apply 跳過這一步。'
                ) -join "`n"
                throw $hint
            }

            $retryable = $status -in @(401, 403, 408, 429, 500, 502, 503, 504)
            if (-not $retryable -or $attempt -eq $MaxAttempts) {
                throw "$Method $uri 失敗（HTTP $status，第 $attempt 次）：$($_.Exception.Message)"
            }

            $delay = [Math]::Min(60, 8 * $attempt)
            Write-Warning "$Method $uri 回傳 HTTP $status（第 $attempt 次），$delay 秒後重試（可能是 RBAC 尚未傳播）..."
            Start-Sleep -Seconds $delay
        }
    }
}

# --- 讀取 Terraform 傳入的環境變數 -------------------------------------------
$script:ProjectEndpoint = (Get-RequiredEnv 'PROJECT_ENDPOINT').TrimEnd('/')
$script:ApiVersion      = 'v1'
$agentName              = Get-RequiredEnv 'AGENT_NAME'
$modelDeployment        = Get-RequiredEnv 'MODEL_DEPLOYMENT'
$agentFilesPath         = Get-RequiredEnv 'AGENT_FILES_PATH'

$policyFile  = Join-Path $agentFilesPath 'IT_Policy.txt'
$metricsFile = Join-Path $agentFilesPath 'system_performance.csv'

foreach ($f in @($policyFile, $metricsFile)) {
    if (-not (Test-Path -LiteralPath $f)) {
        throw "找不到 agent 檔案 '$f'。請先成功執行 Get-SampleData.ps1。"
    }
}

Write-Host '建立模組 7 的 demo agent...'
Write-Host "  專案端點 : $script:ProjectEndpoint"
Write-Host "  模型部署 : $modelDeployment"

# --- 移除同名的舊 agent（讓腳本可重複執行）----------------------------------
$existingAgents = Invoke-ProjectApi -Method GET -Path '/assistants'
if ($existingAgents -and $existingAgents.PSObject.Properties.Name -contains 'data') {
    foreach ($agent in @($existingAgents.data | Where-Object { $_.name -eq $agentName })) {
        Write-Host "  移除同名的舊 agent $($agent.id)"
        Invoke-ProjectApi -Method DELETE -Path "/assistants/$($agent.id)" | Out-Null
    }
}

# --- 上傳檔案 ----------------------------------------------------------------
$policyUpload = Invoke-ProjectApi -Method POST -Path '/files' -Form @{
    purpose = 'assistants'
    file    = Get-Item -LiteralPath $policyFile
}
Write-Host "  已上傳 IT_Policy.txt -> $($policyUpload.id)"

$metricsUpload = Invoke-ProjectApi -Method POST -Path '/files' -Form @{
    purpose = 'assistants'
    file    = Get-Item -LiteralPath $metricsFile
}
Write-Host "  已上傳 system_performance.csv -> $($metricsUpload.id)"

# --- 建立 file_search 用的 vector store --------------------------------------
$policyStore = Invoke-ProjectApi -Method POST -Path '/vector_stores' -Body @{
    name     = "$agentName-it-policy"
    file_ids = @($policyUpload.id)
}
Write-Host "  IT policy vector store：$($policyStore.id)"

# --- 建立 agent --------------------------------------------------------------
$instructions = @(
    'You are an IT support agent for Contoso.',
    'Answer employee questions about IT policy using the file search tool, and cite the policy document.',
    'When asked about system performance, use the code interpreter tool to analyse the provided CSV and, where useful, produce a chart.',
    'If you do not have enough information, say so rather than guessing.'
) -join "`n"

$agent = Invoke-ProjectApi -Method POST -Path '/assistants' -Body @{
    name         = $agentName
    model        = $modelDeployment
    description  = 'AI-3016 module 7 backup demo agent (file search + code interpreter).'
    instructions = $instructions
    tools        = @(
        @{ type = 'file_search' },
        @{ type = 'code_interpreter' }
    )
    tool_resources = @{
        file_search      = @{ vector_store_ids = @($policyStore.id) }
        code_interpreter = @{ file_ids = @($metricsUpload.id) }
    }
}

if (-not $agent.id) {
    throw '建立 agent 失敗：回應沒有 id。'
}

Write-Host "demo agent 就緒：$($agent.id)（$agentName）"

# 把 id 寫到暫存目錄供講師取用。
$stateFile = Join-Path (Split-Path -Parent $agentFilesPath) 'demo-state.json'
$state = @{}
if (Test-Path -LiteralPath $stateFile) {
    $state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json -AsHashtable
}
$state['agent_id']               = $agent.id
$state['agent_name']             = $agentName
$state['it_policy_vector_store'] = $policyStore.id
$state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateFile -Encoding UTF8
Write-Host "  已寫入 $stateFile"