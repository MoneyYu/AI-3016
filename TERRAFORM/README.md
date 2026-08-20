# AI-3016 Backup Demo Environment (Terraform)

> **講師專用**。這份文件與整個 `TERRAFORM/` 資料夾都不是給學員看的。

## 這個 stack 是什麼（以及不是什麼）

課堂上講師會**從零開始現場建立** Foundry 專案與模型部署。這個 Terraform stack 是**備援**：
把同樣的環境一次佈建到「**已完成、可立刻 demo**」的狀態（資源 **＋** 資料平面）。

> ⚠️ **它不是「上課當場失敗才按的緊急開關」。**
> 微調需要 60 分鐘以上、模型部署可能撞配額、RBAC 傳播需要時間、vector store 索引是非同步的。
>
> ✅ **正確用法：開課前 1–2 天 `apply` 並做 smoke test，上課期間保持運作，課後 `destroy`。**

## 前置需求

| 項目 | 說明 |
|---|---|
| Terraform | >= 1.5（實測 1.15.2）|
| PowerShell | 7 以上（`pwsh`），資料平面腳本使用 |
| Azure CLI | 已 `az login`，且已 `az account set` 到目標訂閱 |
| 權限 | 訂閱層級 Owner 或 Contributor + User Access Administrator（本 stack 會建立角色指派）|
| 配額 | 見下方「預檢閘門」 |

本 stack **全程使用 Entra ID（AAD）驗證**：Storage 停用共用金鑰、Foundry 帳戶 `local_auth_enabled = false`。
因此每個資料平面主體都必須有明確的 RBAC 角色，這些角色由 Terraform 一併建立。

## 🚦 步驟 0：預檢閘門（不可略過）

Microsoft 的兩份官方文件在此議題上互相矛盾：

* **退役排程**把 `gpt-5` / `gpt-5-mini` 標為 **GA**；
* **生命週期政策**卻寫明「模型上市滿 **12 個月**後，**新客戶無法建立部署**」，
  而且「既有客戶」是**以訂閱為單位**判定，同租用戶的新訂閱**不繼承**。

`gpt-5` / `gpt-5-mini` 於 2025-08-07 上市，已在 **2026-08-07** 跨過該門檻。
所以「能不能部署」**不能用日期推算**，必須對「實際要用的那個訂閱」實測。

```powershell
cd TERRAFORM/scripts
./Test-ModelAvailability.ps1                        # parity profile（lab 指定的模型）
./Test-ModelAvailability.ps1 -ModelProfile current  # 備援 profile
```

* **講師 demo 訂閱**與**新配發的 Skillable 訂閱**都要各跑一次。
* 若 `parity` 失敗但 `current` 通過 → `apply` 時加上 `-var model_profile=current`，並同步更新 `docs/demo-environment.md`。

## 步驟 1：部署

```powershell
cd TERRAFORM
terraform init
terraform plan  -var group_postfix=0821          # 建議用開課日期 MMDD
terraform apply -var group_postfix=0821
```

`apply` 會**自動執行資料平面**（下載官方範例資料 → 上傳 Blob → 建立 vector store → 建立 demo agent），
整體約 5–10 分鐘。

## 變數

| 變數 | 預設 | 說明 |
|---|---|---|
| `group_postfix` | *（必填）* | 例如 `0821`。限 1–10 個小寫英數字（Storage Account 名稱直接使用）。產生 `AI3016-0821` 與 `Demo0821` 兩個資源群組。|
| `model_profile` | `parity` | `parity` = lab 指定的 `gpt-5.2` + `gpt-5-mini`；`current` = 較新的 `gpt-5.4` + `gpt-5.4-mini`。|
| `chat_capacity` | `50` | 主 chat 部署容量（千 TPM）。|
| `compare_capacity` | `30` | 模組 2 比較用的小模型容量。|
| `finetune_base_capacity` | `30` | 模組 5 微調基底 `gpt-4.1-mini` 的容量。|
| `guarded_capacity` | `20` | 模組 6 掛 guardrail 的獨立部署容量。|
| `finetune_location` | `null` | 微調區域，預設同主區域。|
| `deployer_object_id` | `null` | 資料平面腳本使用的 Entra 物件 ID，預設為 Terraform 執行身分。|
| `enable_data_plane` | `true` | 是否執行資料平面腳本。|
| `enable_demo_agent` | `true` | 是否建立模組 7 的 demo agent。|

## 佈建內容

| 資源 | 用途 |
|---|---|
| `AI3016-<postfix>` 資源群組 | 備援環境本體 |
| `Demo<postfix>` 資源群組 | 空的，給課堂現場從零建立用 |
| Foundry 帳戶（`AIServices`，`project_management_enabled`）+ 專案 | 全部 7 個模組 |
| `gpt-5.2` 部署 | 模組 1 / 3 / 4 |
| `gpt-5-mini` 部署 | 模組 2 的並排比較 |
| `gpt-4.1-mini` 部署 | 模組 5 微調的「微調前」基準 |
| `gpt-5.2-guarded` 部署 + 自訂 guardrail | 模組 6（**刻意獨立**，嚴格門檻不會影響其他 demo）|
| Storage Account（AAD-only）+ 3 個容器 | 範例資料暫存 |
| 預建 vector store（6 份 Margie's Travel 手冊）| 模組 4 file_search 保底 |
| 預建 demo agent（file_search + code_interpreter）| 模組 7 保底 |

## 資料平面腳本

| 腳本 | 何時執行 | 說明 |
|---|---|---|
| `Test-ModelAvailability.ps1` | **`apply` 之前，手動** | 預檢閘門 |
| `Get-SampleData.ps1` | `apply` 期間自動 | 下載官方範例資料並上傳 Blob |
| `New-DemoVectorStore.ps1` | `apply` 期間自動 | 建立含 6 份手冊的 vector store |
| `New-DemoAgent.ps1` | `apply` 期間自動 | 建立模組 7 的 demo agent |
| `Start-FineTune.ps1` | **開課前 1–2 天，手動** | `gpt-4.1-mini` 監督式微調（60 分鐘以上）|

只重跑資料平面：

```powershell
terraform apply -replace='terraform_data.sample_data[0]' -var group_postfix=0821
terraform apply -replace='terraform_data.vector_store[0]' -var group_postfix=0821
terraform apply -replace='terraform_data.demo_agent[0]'  -var group_postfix=0821
```

## 步驟 2：微調（**必須課前執行**）

```powershell
cd TERRAFORM
$ep = terraform output -raw azure_openai_v1_endpoint
$rg = terraform output -raw resource_group_name
$acct = terraform output -raw foundry_account_name

cd scripts
./Start-FineTune.ps1 -Endpoint $ep -ResourceGroup $rg -AccountName $acct -Deploy
```

### 為什麼不是 lab 寫的 `gpt-5`

Lab 04b 要求在 `gpt-5` 上做 **Supervised** 微調，但官方
[微調支援表](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure?pivots=azure-openai#fine-tuning-models)
列出 `gpt-5` **只支援 RFT**，且註明：

> GPT-5 support for reinforcement fine-tuning is generally available, but access is **gated and available by invitation only**.

`gpt-4.1-mini` 是唯一同時滿足下列所有條件的模型：

* 支援 **SFT** 且狀態為 **GA**
* 基底不是 **Deprecated**（是 Legacy，仍可建立新部署）
* 在 `swedencentral` 屬於微調的**標準區域**
* 支援 **Developer** 部署型別（lab 指定的型別）
* 訓練資料格式與 lab 附的 `travel-finetune-hotel.jsonl` **完全相容**

> ⚠️ **整個 `gpt-4.1` 系列在 2027-04-14 退役**，屆時若 Microsoft 仍未把 SFT 開放給 gpt-5.x，
> 微調示範將需要改用 `Llama-3.3-70B-Instruct`（Global training、目前為 public preview）或改為純講解。
> 每次開課前都要重新確認。

> 註：`gpt-4.1`（完整版）在測試訂閱的 `swedencentral` 配額已用盡（3075/3075），這也是選 `-mini` 的實務理由之一。

## 步驟 3：驗證環境可用

```powershell
$tok  = az account get-access-token --resource https://ai.azure.com --query accessToken -o tsv
$base = terraform output -raw azure_openai_v1_endpoint
$h    = @{ Authorization = "Bearer $tok" }

# 主 chat 部署
$r = Invoke-RestMethod -Method POST -Uri "$base/responses" -Headers $h `
     -ContentType 'application/json' `
     -Body (@{ model = 'gpt-5.2'; input = 'Reply with exactly: OK' } | ConvertTo-Json)
($r.output | Where-Object type -eq 'message').content.text
```

> 提示：REST 回應**沒有** `output_text` 欄位（那是 OpenAI SDK 的便利屬性），要自己從 `output` 陣列取。

預期結果：

| 檢查 | 預期 |
|---|---|
| `gpt-5.2` 回應 | 正常回覆 |
| file_search（`vector_store_id` 見 `.sample-data/demo-state.json`）| 能列出 Dubai / Las Vegas / London / New York / San Francisco |
| code_interpreter | 能算出 `sqrt(16) = 4` |
| `gpt-5.2-guarded` | Foundry portal 中該部署顯示套用 `ai3016-strict-guardrail` |
| demo agent | Foundry portal 的 Agents 中看得到 `ai3016-demo-agent` |

Demo 應用程式的 `.env` 直接取用：

```powershell
terraform output -raw demo_env_file | Set-Content .env
```

## 必須在 Portal 手動完成的步驟

| 項目 | 原因 |
|---|---|
| 模組 2 的評估（evaluation）執行 | 非同步且結果非決定性；建議課前先跑一次留一份完成的結果當保底畫面 |
| 模型型錄 / leaderboard 畫面 | 即時 portal 內容，無法預建 |
| Agent 對話與 Code Interpreter session | 無法保溫，當天需重開 session 做 smoke test |
| VS Code 環境 | 擴充套件、clone、Python venv、`az login` 屬工作站設定 |

## 步驟 4：課後清除

```powershell
terraform destroy -var group_postfix=0821
```

> **Cognitive account 有約 48 小時的軟刪除名稱保留。**
> 若需要在 destroy 後立刻用相同 `group_postfix` 重建，把 `MAIN.tf` 中
> `random_str = "gen"` 改成 `random_str = random_string.rid.result` 取得新的隨機後綴。

## 疑難排解

| 症狀 | 原因 | 解法 |
|---|---|---|
| Storage `You do not have the required permissions` | RBAC 角色指派尚未傳播 | 腳本已內建重試（8 次、遞增延遲）。若持續失敗，確認執行 `az` 的身分與 `deployer_object_id` 一致 |
| Cognitive 帳戶 data plane 回 401 | 缺 `custom_subdomain_name`（區域端點不支援 Entra ID）| 本 stack 已設定；若自行新增帳戶請一併設定 |
| 模型部署 `InsufficientQuota` | 訂閱配額不足 | 先跑 `Test-ModelAvailability.ps1`；降低 `*_capacity` 變數或改用 `model_profile=current` |
| Cognitive 帳戶名稱「已存在」 | 48 小時軟刪除名稱保留 | 換 `group_postfix` 或改用 `random_string.rid` |
| `New-DemoAgent.ps1` 回 404 | Agent Service REST 介面變更 | 依錯誤訊息在 portal 手動建立，或設 `-var enable_demo_agent=false` |

## 檔案結構

```
TERRAFORM/
├─ MAIN.tf      providers / variables / locals / resource groups
├─ MOD.tf       所有資源 + 資料平面接線
├─ OUTPUT.tf    endpoints 與名稱（不含祕密）
├─ README.md    本文件
└─ scripts/
   ├─ Test-ModelAvailability.ps1   預檢閘門（apply 前手動）
   ├─ Get-SampleData.ps1           下載官方範例資料 + 上傳 Blob
   ├─ New-DemoVectorStore.ps1      模組 4 的 vector store
   ├─ New-DemoAgent.ps1            模組 7 的 demo agent
   └─ Start-FineTune.ps1           模組 5 微調（課前手動）
```