# AI-3016 Demo / Backup 環境

> **講師專用文件**，不對學員公開。
> 部署與操作步驟請看 [`../TERRAFORM/README.md`](../TERRAFORM/README.md)；
> 教學內容請看 [`teaching-guide.md`](teaching-guide.md)。
>
> **本文所有模型與區域結論的查核基準日：2026-08-20。每次開課前都必須重跑。**

---

## 1. 這個環境的定位

課堂上講師會**從零開始現場建立** Foundry 專案與模型部署；`TERRAFORM/` 這個 stack 是**備援**，
把同樣的環境一次佈建到「已完成、可立刻 demo」的狀態（資源 **＋** 資料平面）。

> ⚠️ **它不是「上課當場失敗才按的緊急開關」。**
> 微調需要 60 分鐘以上、模型部署可能撞配額、RBAC 傳播需要時間、vector store 索引是非同步的。
>
> ✅ **正確用法：開課前 1–2 天 `apply` 並 smoke test，上課期間保持運作，課後 `destroy`。**

---

## 2. 🔬 模型選擇：完整證據

### 2.1 生命週期規則（決定「能不能部署」）

來源：[Foundry Models lifecycle and support policy](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirements)（`ms.date: 2026-07-24`）

| 階段 | 可否建立**新**部署 | 既有部署 |
|---|---|---|
| Preview | 可 | 可 |
| **GA** | 可 | 可 |
| **Legacy** | **可**（直到 Deprecated）| 可 |
| **Deprecated** | **僅限「該 Azure 訂閱曾經部署過該確切版本」的既有客戶；新訂閱不可** | 可 |
| **Retired** | **不可** | **不可**（`410 Gone`）|

關鍵條文（原文）：

> **At 12 months from launch**, existing customers can continue to create and manage deployments.
> **New customers can't access the model.**

> "Existing customer" is determined at the **subscription level**… A new subscription under the
> same tenant **doesn't inherit** access.

🔑 **對本課的意義**：Skillable 實驗訂閱是獨立訂閱（且未必全新，可能是回收的），
講師 demo 訂閱又是另一個。**同一個 Deprecated 模型可能在講師機器上能部署、在學員環境卻不能。**
因此 backup stack **預設一律排除 Deprecated 模型**（可攜性優先）。

### 2.2 課程實際使用的模型

| Lab / 素材 | 模型 | 出處 |
|---|---|---|
| Lab 01 / 03 / 04a / 06 | `gpt-5.2` | 各 lab「search for `gpt-5.2`… deploy it using the default settings」|
| Lab 02 | `gpt-5.2` **與** `gpt-5-mini` | 「You need to deploy **gpt-5.2** and **gpt-5-mini**」|
| Lab 04b（模組 5）| 基底 `gpt-5`、**Supervised**、Training type Standard、部署型別 **Developer**、限 NCUS / Sweden Central | `mslearn-ai-studio/Instructions/Exercises/04b-finetune-model.md` |
| M07 agent lab | 未指名模型；工具用 **File search + Code interpreter** | `mslearn-ai-agents/…/01-build-agent-portal-and-vscode` |
| 投影片程式碼 | `gpt-4.1`（slide 22/23/24/32/36 硬寫）| `PPT/AI-3016-ENU-PowerPoint-01.pptx` |

### 2.3 退役查核結果

來源：[Model retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)（`ms.date: 2026-08-19`）

| 模型 | 版本 | **基底生命週期** | 退役日 | 距查核日 | swedencentral | 判定 |
|---|---|---|---|---|---|---|
| `gpt-5.2` | 2025-12-11 | **GA** | 2027-06-08 | ~9.6 月 | ✅ | ✅ **主力**（`parity` profile）|
| `gpt-5-mini` | 2025-08-07 | GA | 2027-02-09 | **~5.7 月** | ✅ | ⚠️ 已跨過 12 個月門檻（2026-08-07）→ **必須預檢** |
| `gpt-5` | 2025-08-07 | GA | 2027-02-09 | **~5.7 月** | ✅ | ⚠️ 同上；微調路徑另有問題（§2.4）|
| `gpt-4.1` | 2025-04-14 | **Legacy** | 2027-04-14 | ~7.8 月 | ✅ | ⚠️ 可部署，但測試訂閱配額已用盡 |
| `gpt-4.1-mini` | 2025-04-14 | **Legacy** | 2027-04-14 | ~7.8 月 | ✅ | ✅ **微調基底**（§2.4）|
| `gpt-5.4` | 2026-03-05 | GA | 2027-09-02 | ~12.4 月 | ✅ | ✅ `current` profile |
| `gpt-5.4-mini` | 2026-03-17 | GA | 2027-09-21 | ~12.5 月 | ✅ | ✅ `current` profile |
| `gpt-5.5` | 2026-04-24 | GA | 2027-10-26 | ~14.2 月 | ✅ | ➖ 較低配額分級訂閱**可能需另外申請配額** |
| `gpt-5.6-sol/terra/luna` | 2026-07-09 | GA（最新）| 2028-01-11 | ~16.8 月 | ✅ | ➖ 同上；且 Chat Completions **與** function tools 不可同時使用（除非 `reasoning_effort=none`）|
| `gpt-4o` / `gpt-4o-mini` / `o1` / `o3-mini` | — | **Deprecated** | — | — | — | ❌ **排除**：新訂閱無法建立部署 |
| `o4-mini` | 2025-04-16 | **Deprecated** | **2026-10-16** | **~1.9 月** | — | ❌ **最先退役，絕對排除** |
| `gpt-5-chat` / `gpt-5.1-chat` / `gpt-5.2-chat` / `gpt-5.3-chat` | — | **Retired** | 已過 | — | — | ❌ **禁用** |

> ℹ️ **關於配額分級的常見誤解**：官方原文是
> 「Some quota tiers **require quota requests** for `gpt-5.6` to deploy this model.
> **Tier 5 and Tier 6** subscriptions **have quota by default**.」
> → 是**較低分級**的訂閱需要另外申請，不是「必須是 Tier 5/6」。

### 2.4 ⛔ 微調：Lab 04b 與官方文件矛盾

官方[微調支援表](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure?pivots=azure-openai#fine-tuning-models)
（`ms.date: 2026-08-19`；[另一份獨立頁面](https://learn.microsoft.com/azure/foundry/openai/how-to/fine-tuning)內容完全一致）：

| 模型 | 微調方法 | 微調狀態 | **基底生命週期** | 基底退役日 | 微調後部署退役日 | 標準區域 | Developer 部署 | 判定 |
|---|---|---|---|---|---|---|---|---|
| `gpt-4o-mini` (2024-07-18) | SFT | GA | **Deprecated** | 2027-04-14 | 2027-10-01 | NCUS, SC | ✅ | ❌ 新訂閱不可部署 |
| `gpt-4o` (2024-08-06) | SFT, DPO | GA | **Deprecated** | 2027-04-14 | 2027-10-01 | EUS2, NCUS, SC | ✅ | ❌ 新訂閱不可部署 |
| **`gpt-4.1`** (2025-04-14) | **SFT**, DPO | GA | Legacy | 2027-04-14 | 2027-10-14 | NCUS, **SC** | ✅ | ⚠️ 測試訂閱配額 3075/3075 已用盡 |
| **`gpt-4.1-mini`** (2025-04-14) | **SFT**, DPO | GA | Legacy | 2027-04-14 | **2027-10-14** | NCUS, **SC** | ✅ | ⭐ **採用** |
| `gpt-4.1-nano` (2025-04-14) | SFT, DPO | GA | Legacy | 2027-04-14 | 2027-10-14 | NCUS, SC | ✅ | 訓練最快，但基底品質最低 |
| `o4-mini` (2025-04-16) | RFT | GA | **Deprecated** | **2026-10-16** | 2027-10-16 | EUS2, SC | ❌ | ❌ 兩個月內退役 |
| **`gpt-5`** (2025-08-07) | **RFT only** | GA（**gated**）| GA | 2027-02-09 | — | NCUS, SC | ✅ | ❌ 非 SFT + 需邀請 |
| `Ministral-3B` (2411) | SFT | **Public preview** | 未列於退役表 | — | — | 僅 Global | ❌ | ⚠️ preview |
| `Qwen-32B` | SFT | **Public preview** | 未列於退役表 | — | — | 僅 Global | ❌ | ⚠️ preview |
| **`Llama-3.3-70B-Instruct`** | SFT | **Public preview** | **GA** | **無公告退役日** | — | 僅 Global | ❌ | ⚠️ 唯一長壽基底，但微調是 preview |
| `gpt-oss-20b` | SFT | **Public preview** | Preview | — | — | 僅 Global | ❌ | ⚠️ preview |

`gpt-5` 那一列的原文註腳：

> GPT-5 support for **reinforcement fine-tuning** is generally available, but access is
> **gated and available by invitation only**. Contact your Microsoft account team if you're
> interested in enrollment.

#### 🔴 結論

**目前「沒有」任何一個非 Legacy／非 Deprecated 的 Azure OpenAI 模型支援 SFT。**
整個 gpt-5.x 家族（`5.1` / `5.2` / `5.4` / `5.5` / `5.6`）**完全不在微調清單內**；
唯一沾到邊的 `gpt-5` 只有 gated 的 RFT。所有 SFT 能力都集中在 **gpt-4.1 系列（Legacy）**，
且**整批在 2027-04-14 一起到期**。

> 📌 **駁回一項網路說法**：網路搜尋會宣稱「gpt-5.2 與 gpt-5.4 已支援 SFT」，
> 引用來源是 Azure 行銷部落格與第三方 wiki。**兩份官方 Learn 微調支援表都沒有列入這兩個模型**，
> 故不採信。（course-prep 規則：web 摘要可能是 AI 合成的，一律以 Learn 為準。）

#### 選定：`gpt-4.1-mini`

唯一同時滿足：SFT ＋ 微調狀態 GA ＋ 基底非 Deprecated ＋ `swedencentral` 標準區域 ＋
支援 Developer 部署型別 ＋ 與 lab 附的 `travel-finetune-hotel.jsonl`（Chat Completions
conversational JSONL）格式完全相容。

**已實測驗證（2026-08-20）**：在 `swedencentral` 對 `gpt-4.1-mini` 的 Supervised 微調工作
`ftjob-1c603d5ea68149bc95927401fb046dbf` **成功完成**（約 55 分鐘），並成功部署到 Developer tier
`gpt-4.1-mini-ft-travel`；後續透過 Responses API 推論，得到預期的 Paris travel-assistant 回應。

> ⚠️ **2027-04-14 之後**：若 Microsoft 仍未把 SFT 開放給 gpt-5.x，微調示範必須改用
> `Llama-3.3-70B-Instruct`（Global training、微調仍為 public preview）或改為純講解。

---

## 3. 區域決策：`swedencentral`

| 需求 | `swedencentral` | `northcentralus` | `eastus2` |
|---|---|---|---|
| Lab 04b **明文指定**的區域 | ✅ | ✅ | ❌ |
| Responses API 支援區域 | ✅ | ✅ | ✅ |
| Foundry Agents 支援 | ✅ | ✅ | ✅ |
| Agent 工具：File Search / Code Interpreter（M07 實際用到）| ✅ / ✅ | ✅ / ✅ | ✅ / ✅ |
| Agent 工具：Function（保險，M07 未用到）| ✅ | **❌ no** | ✅ |
| Agent 工具：Computer Use | ✅ | ❌ | ✅ |
| 微調「標準區域」：`gpt-4.1-mini` (SFT) | ✅ | ✅ | ❌（僅 Global training）|
| `gpt-5.2` / `gpt-5-mini` / `gpt-4.1-mini` Global Standard | ✅ | ✅ | ✅ |

**結論**：`swedencentral` 與 `northcentralus` 都滿足硬性需求；選 **`swedencentral`** 是因為
**Agent 工具覆蓋最完整**，單一區域即可涵蓋全部 7 課，不必拆成「一般 demo 在 A 區、微調在 B 區」的雙區堆疊。
需要改變微調區域時，必須建立使用該區域的**另一個** Foundry account/project；單一帳戶的 endpoint 無法由變數搬遷。

> ⚠️ 注意：Global Standard 部署的**推論流量不保證留在瑞典／歐盟**。
> 有資料落地需求時需改用 Data Zone 或 Standard 部署型別。

---

## 4. 🚦 預檢閘門（每次開課前必跑）

Microsoft 的兩份文件互相矛盾（退役表說 GA，生命週期政策說 12 個月後新客戶不可用），
**不能用日期推算取代實測**。

```powershell
cd TERRAFORM/scripts
./Test-ModelAvailability.ps1                        # parity profile
./Test-ModelAvailability.ps1 -ModelProfile current  # 備援 profile
```

腳本會檢查：

1. 模型是否出現在該訂閱 / 區域的型錄（`az cognitiveservices model list`）
2. 是否有 `GlobalStandard` SKU
3. 標準配額是否足夠（`az cognitiveservices usage list`）
4. 微調後模型的 **Developer tier** 配額（`OpenAI.DeveloperTier.gpt4.1-mini-finetune`）

**必須在兩種訂閱各跑一次**：講師 demo 訂閱、**新配發的** Skillable 訂閱（不是回收的舊環境）。
任一 parity 模型失敗 → 把 `current` profile 升為預設，並更新本文件。

> 💡 配額鍵名的陷阱：gpt-4.1 系列在配額 API 中是 **`gpt4.1`**（少了第一個點），
> 例如 `OpenAI.GlobalStandard.gpt4.1-mini`。腳本已處理這個對應。

### 2026-08-20 測試訂閱的實際結果

```
[ OK ] gpt-5.2        ver=2025-12-11   配額剩餘 1720（需要 70：主 chat 50 + guarded 20）
[ OK ] gpt-5-mini     ver=2025-08-07   配額剩餘 1850（需要 30）
[ OK ] gpt-4.1-mini   ver=2025-04-14   配額剩餘 7000（需要 30）
[ OK ] finetune       OpenAI.DeveloperTier.gpt4.1-mini-finetune 配額剩餘 500
```

---

## 5. 兩套模型 Profile

| Profile | 模型 | 用途 |
|---|---|---|
| **`parity`（預設）** | `gpt-5.2` + `gpt-5-mini` + `gpt-4.1-mini`(FT) | 與 lab 完全一致：學員看到什麼、講師就 demo 什麼 |
| **`current`（備援）** | `gpt-5.4` + `gpt-5.4-mini` + `gpt-4.1-mini`(FT) | `gpt-5*` 因 Deprecated／配額失敗時切換 |

```powershell
terraform apply -var group_postfix=0821 -var model_profile=current
```

**為什麼預設是 lab parity 而不是「最新 GA」**：講師 demo 必須與學員螢幕上看到的一致。
course-prep 的「優先用最新 GA」規則在此作為**平手時的決勝條件**，而不是推翻官方 lab 的理由。
決策順序為：① 官方 lab 指定的模型（通過預檢）→ ② 能力等價的 GA 替代（實測過）→ ③ 最新 GA。

---

## 6. 安全設計：Entra ID（AAD）Only

公司政策禁用帳戶／存取金鑰，因此整個 stack：

| 資源 | 設定 |
|---|---|
| Storage Account | `shared_access_key_enabled = false`；provider 設 `storage_use_azuread = true` |
| Foundry 帳戶（`AIServices`）| `local_auth_enabled = false` **且**設定 `custom_subdomain_name`（區域端點不支援 Entra ID token）|
| 資料平面腳本 | 以 `az account get-access-token` 取得 bearer token（先試 `https://ai.azure.com`，退回 `https://cognitiveservices.azure.com`）|
| RBAC | 部署者：`Storage Blob Data Contributor`、`Cognitive Services User`、`Cognitive Services OpenAI Contributor`；Foundry 受控識別：`Storage Blob Data Reader` |

> RBAC 角色指派需要時間傳播，資料平面腳本內建 401/403 重試（遞增延遲）。
> ⚠️ 實測發現 `az storage` 的權限錯誤訊息**不一定包含 401/403 字樣**
>（可能只寫 "You do not have the required permissions"），重試判斷式必須夠寬。

---

## 7. 預建內容 vs 無法預建

| 課程活動 | 可否預建 | 作法 |
|---|---|---|
| M02 模型型錄 / leaderboard | ❌ 即時 portal 內容 | 無法預建，照 portal 現況講 |
| M02 合成資料集評估 | ⚠️ 非同步、非決定性 | **課前先跑完一份 evaluation** 當保底畫面 |
| M03 chat app | ✅ | 部署 + 端點 + RBAC 由 Terraform 完成 |
| M04 vector store / brochures | ✅（保底）| 預建含 6 份 Margie's Travel 手冊的 vector store；lab 程式仍會自建一份 |
| M04 `web_search` | ❌ 即時 | 無法預建 |
| M05 微調 | ❌ 當場來不及 | **必須課前執行** `Start-FineTune.ps1`（60 分鐘以上）|
| M06 guardrail | ✅ 可持久化 | `azurerm_cognitive_account_rai_policy` 預建；**阻擋是機率性的**，demo 重點放「政策已掛上」而非保證特定回應 |
| M07 agent | ⚠️ 部分 | agent 與檔案可持久；**對話與 Code Interpreter session 無法保溫**，當天需重開並 smoke test |
| VS Code 練習 | ❌ 屬工作站設定 | 擴充套件、clone、Python venv、`az login` 寫進課前清單 |

### 隔離原則

M06 的嚴格 guardrail **不掛在共用的主部署上**，而是另建 `<chat model>-guarded` 部署承載（`parity` = `gpt-5.2-guarded`；`current` = `gpt-5.4-guarded`）。
否則模組 1/3/4 的 demo 會被嚴格門檻干擾。

---

## 8. 投影片的 `gpt-4.1` 落差

投影片 22/23/24/32/36 的程式碼硬寫 `model="gpt-4.1"`，但 lab 實際部署的是 `gpt-5.2`。

**處置**：demo 程式改讀環境變數 **`MODEL_DEPLOYMENT`**（由 `terraform output -raw demo_env_file` 提供），
既能實跑又不綁死版本。**絕不**把新模型用 `gpt-4.1` 這個部署名稱部署（會誤導學員）。
請講師口頭說明這個差異。

---

## 9. 每次開課前的重查清單

- [ ] 重新開啟[退役排程](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)，確認 `gpt-5.2` / `gpt-5-mini` / `gpt-4.1-mini` 的 lifecycle 未變
- [ ] 確認 gpt-5.x 是否已開放 SFT（若有，微調示範可回歸 lab 原文）
- [ ] `Test-ModelAvailability.ps1` 在**講師訂閱**與**新 Skillable 訂閱**各跑一次
- [ ] `terraform apply` 並確認 21 個資源、vector store 6 份文件、demo agent 已建立
- [ ] `Start-FineTune.ps1` 課前完成，並等候 Developer-tier `provisioningState=Succeeded`（`az ... deployment create` 回傳成功不代表立刻可推論）
- [ ] 逐一 smoke test：chat、file_search、code_interpreter、guarded 部署、agent
- [ ] 課後 `terraform destroy`
