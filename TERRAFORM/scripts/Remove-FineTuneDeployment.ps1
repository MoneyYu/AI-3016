#Requires -Version 7.0
<#
.SYNOPSIS
    在 Terraform destroy 前移除 Start-FineTune.ps1 建立的所有 fine-tuned Developer-tier 部署。

.DESCRIPTION
    微調後的模型名稱是 fine-tuning job 執行後才知道，所以不能用一般
    azurerm_cognitive_deployment 放進 Terraform state。若不先刪除它，
    Azure 會拒絕刪除 Foundry account：
      CannotDeleteAccountWithDeployments

    此腳本由 terraform_data.finetune_deployment_cleanup 的 destroy provisioner
    呼叫。它用 model name 中的 `.ft-` 發現本專案帳戶內所有 fine-tuned
    deployment，而非耦合某個 suffix；所以即使講師用 Start-FineTune.ps1 的
    自訂 -Suffix 重跑，也能在 destroy 前清掉。

    僅明確的 Azure 404 / ResourceNotFound 是「已清理」的正常情況。登入、
    RBAC、訂閱或暫時性 control-plane 錯誤都會重試或 throw，絕不靜默跳過。
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RequiredEnv {
    param([Parameter(Mandatory)][string] $Name)

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "必要的環境變數 '$Name' 未設定。"
    }
    return $value
}

function Invoke-AzCli {
    param(
        [Parameter(Mandatory)][string[]] $Arguments,
        [switch] $AllowNotFound,
        [int] $MaxAttempts = 6
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $output = & az @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        $text = ($output | Out-String).Trim()

        if ($exitCode -eq 0) {
            return $text
        }

        # Only an explicit missing-resource response is a successful no-op.
        if ($AllowNotFound -and $text -match '(?i)ResourceNotFound|\b404\b|Could not be found') {
            return $null
        }

        # Azure serialises control-plane operations per Cognitive Services account.
        # Deleting a deployment while another account child resource is being
        # deleted returns 409 RequestConflict or 412. Match those SPECIFIC
        # transient messages rather than blanket-retrying every 409, because a
        # bare 409 can also be a genuine, non-transient conflict.
        $transientConflict = $text -match '(?i)RequestConflict|Another operation is in progress|AnotherOperationInProgress|\b412\b'
        $retryable = $transientConflict -or $text -match '(?i)\b408\b|\b429\b|\b50[0-4]\b|TooManyRequests|ServiceUnavailable|InternalServerError|GatewayTimeout'
        if (-not $retryable -or $attempt -eq $MaxAttempts) {
            throw "az $($Arguments -join ' ') 失敗（exit $exitCode，第 $attempt 次）：$text"
        }

        $delay = [Math]::Min(60, 10 * $attempt)
        Write-Warning "az control-plane 暫時失敗（第 $attempt 次），$delay 秒後重試..."
        Start-Sleep -Seconds $delay
    }
}

$resourceGroup = Get-RequiredEnv 'RESOURCE_GROUP'
$accountName   = Get-RequiredEnv 'ACCOUNT_NAME'

# terraform destroy can be retried after a partial failure. Account 404 means
# there is nothing left to clean up; authentication/authorization errors throw.
$account = Invoke-AzCli -Arguments @(
    'cognitiveservices', 'account', 'show',
    '--resource-group', $resourceGroup,
    '--name', $accountName,
    '--output', 'json'
) -AllowNotFound

if ($null -eq $account) {
    Write-Host "Foundry account '$accountName' no longer exists; no fine-tuned deployment cleanup is needed."
    exit 0
}

$deploymentJson = Invoke-AzCli -Arguments @(
    'cognitiveservices', 'account', 'deployment', 'list',
    '--resource-group', $resourceGroup,
    '--name', $accountName,
    '--output', 'json'
)
$deployments = @($deploymentJson | ConvertFrom-Json)

# A fine-tuned model resource name contains `.ft-` (for example
# gpt-4.1-mini-2025-04-14.ft-<jobid>-ft-travel). This catches every manually
# created fine-tuned deployment while leaving Terraform-managed base models
# untouched.
$fineTunedDeployments = @($deployments | Where-Object {
    $_.properties.model.name -match '\.ft-'
})

if ($fineTunedDeployments.Count -eq 0) {
    Write-Host 'No fine-tuned deployments remain; cleanup is already complete.'
    exit 0
}

Write-Host "Removing $($fineTunedDeployments.Count) untracked fine-tuned deployment(s) before the Foundry account is destroyed..."
foreach ($deployment in $fineTunedDeployments) {
    $deploymentName = $deployment.name
    Write-Host "  Deleting '$deploymentName'..."

    Invoke-AzCli -Arguments @(
        'cognitiveservices', 'account', 'deployment', 'delete',
        '--resource-group', $resourceGroup,
        '--name', $accountName,
        '--deployment-name', $deploymentName,
        '--only-show-errors'
    ) | Out-Null
}

$timeout = [TimeSpan]::FromMinutes(10)
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($true) {
    $remainingJson = Invoke-AzCli -Arguments @(
        'cognitiveservices', 'account', 'deployment', 'list',
        '--resource-group', $resourceGroup,
        '--name', $accountName,
        '--output', 'json'
    )
    $remainingFineTunes = @($remainingJson | ConvertFrom-Json | Where-Object {
        $_.properties.model.name -match '\.ft-'
    })

    if ($remainingFineTunes.Count -eq 0) {
        Write-Host 'All fine-tuned deployments have been removed.'
        break
    }
    if ($sw.Elapsed -gt $timeout) {
        $names = $remainingFineTunes.name -join ', '
        throw "Timed out waiting for fine-tuned deployment(s) to be removed: $names"
    }

    Write-Host "  Waiting for $($remainingFineTunes.Count) fine-tuned deployment(s) to be removed..."
    Start-Sleep -Seconds 15
}