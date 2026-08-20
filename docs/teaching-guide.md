# AI-3016 講師備課指南：Develop generative AI apps in Azure
> **講師專用**：本文件是 AI-3016 的授課前準備、課中決策與故障備援手冊，不是學員教材。
> 請勿直接發給學員；學員應使用 Microsoft Learn 與 hosted lab 環境中的練習說明。
> [!CAUTION]
> ## 課程已改版：請勿重用 2025 年以前的素材
>
> AI-3016 已歷經多次重大改版。**May 2025** 移除了 `Prompt Flow`、加入 Azure AI Foundry SDK，
> 並更新課程名稱；**December 2025** 改用 Foundry Tools 與 Microsoft Foundry 品牌；
> **March 2026** 依新版 AI-103 與 agentic positioning 全面更新投影片和 lab；**May 2026**
> 僅修正連結與小型錯誤。
>
> 因此，講師不得使用舊版的 `Prompt Flow` 示範、Azure AI Studio 截圖、Azure AI Foundry 名稱，
> 或舊 lab 步驟。請每次授課前從 MCT Download Center 取得最新版教材，並以本指南連結的
> Learn 與 lab repo 為準。
> [!IMPORTANT]
> **本文件的模型、區域與生命週期結論查核基準日為 2026-08-20。**
> Microsoft Foundry 模型、配額、portal UI、SDK 與 lab 會持續變更；所有部署可用性都必須在
> **實際授課訂閱**重新驗證，不能以講師個人訂閱的結果推論 Skillable 訂閱。
---

---

## 1. 課程概覽

### 課程定位
**AI-3016: Develop generative AI apps in Azure** 是一天的 instructor-led 課程。它讓有程式開發
基礎的學員，以 Microsoft Foundry 為核心，理解如何選模型、建立 chat app、使用 tools、
優化行為、加入安全防護，並初步建立 AI agents。
請用下列一句話開場：
> 「今天不是要把 Azure AI 的所有服務都講完；我們要用 Microsoft Foundry，把
> Generative AI 與 Agents 的開發決策串成一條可實作的路徑。」
本課的價值不在逐字朗讀投影片，而在講師把「為什麼要這樣選」、「何時會失敗」與
「產品變更後如何驗證」說清楚。Trainer Prep Guide 明確指出，投影片只涵蓋 Learn 的一部分；
Learn 是課後延伸與細節查閱來源。

### 時長與教學範圍
| 項目 | 說明 |
|---|---|
| 授課型態 | 一天 instructor-led |
| 建議教學時間 | 約 6.5 小時的講授、示範與指導，不含學員自行延伸 |
| 實驗形式 | hosted lab 環境中的逐步操作；M01–M06 使用 `mslearn-ai-studio`，M07 使用獨立的 `mslearn-ai-agents` repo |
| 主要範圍 | Generative AI、Foundry Models、Responses API、tools、RAG、fine-tuning、Responsible AI、agents |
| 明確非範圍 | 完整 Azure AI 工作負載、完整 AI-103 考試、vision、language、speech、information extraction 的深入課程 |
| 教材順序 | 依投影片順序授課，每段講解後立刻進入對應 exercise，讓概念立即轉成操作 |

### 對象
本課適合：
- 準備開始開發 generative AI app 的開發人員。
- 已有 Azure 與 Python 或 C# 經驗、希望採用 Microsoft Foundry 的 AI engineers。
- 需要理解模型選擇、RAG、tool calling、安全控制與 agent 開發流程的技術人員。
- 需要能判斷「用 prompt、RAG 或 fine-tuning」的 solution designers。
本課**不假設**學員已經是 LLM 專家；但它不是完全零程式的課程。遇到基礎程式問題時，
把學員帶回既有 Python/C# 知識與 Learn 文件，不要把課堂時間變成語言入門課。

### 學員先備條件
| 類別 | 課前應具備 | 講師處置 |
|---|---|---|
| AI 基礎 | 基本 AI 概念與 Azure AI services 概念 | 第一段用 workload map 對齊詞彙，不重講 ML 數學 |
| 程式能力 | 可閱讀與修改 Python 或 C# | 本版 labs 已整併為 Python；C# 學員可理解概念，但不宜現場改寫所有 lab |
| Azure | 能登入 lab tenant、理解 resource group 與 subscription | 先確認 Skillable training key、訂閱與 portal 登入 |
| 開發工具 | 可使用 browser、terminal、VS Code | M07 之前先確認 VS Code、Microsoft AI Toolkit extension、Python 與 `az login` |
| 講師能力 | 熟悉 Microsoft Foundry、generative AI models、Foundry Tools、Python 或 C# | 先親自完成全部 labs；能說明 KC 正解與錯誤選項為何不對 |

### 講師開場的 5 分鐘檢查
1. 確認所有學員可登入 Microsoft Learn 與 hosted lab。
2. 顯示今天的範圍是 **Generative AI and Agents**，不是完整 Azure AI service catalog。
3. 說明 lab 是主要學習載體，投影片是建立共同心智模型的工具。
4. 提前說明每個 exercise 都會建立新的 Foundry project，這是刻意的模組化設計。
5. 告知產品與 UI 持續變動：lab 與畫面略有不同時，先讀目標、再找相同功能，而非只找相同按鈕。
---

## 2. 課程地圖：7 個課堂模組
> [!NOTE]
> Microsoft Learn learning path `develop-generative-ai-apps` 包含 **6 個 modules**。
> 投影片與 Trainer Prep Guide 有 **7 lessons**；M07 是獨立 Learn module，**不屬於該 learning path**，
> 且使用第二個 lab repo。不要告訴學員 M07 是 learning path 的第七單元。
| 模組 | Lesson | Learn module | Exercise / Lab | 官方建議 lab 時間 | 講師的教學判斷 |
|---|---|---|---|---:|---|
| M01 | Plan and prepare to develop AI solutions on Azure | [`prepare-azure-ai-development`](https://learn.microsoft.com/en-us/training/modules/prepare-azure-ai-development/) | [01-Explore-ai-studio](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/01-Explore-ai-studio.html) | L200, 30 分鐘 | 熟悉者可縮為 portal demo |
| M02 | Select, deploy, and evaluate Microsoft Foundry Models | [`model-catalog-evaluate`](https://learn.microsoft.com/en-us/training/modules/model-catalog-evaluate/) | [02-model-catalog-evaluation](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/02-model-catalog-evaluation.html) | L300, 45 分鐘 | 保留評估思路；leaderboard 是即時內容 |
| M03 | Develop a generative AI chat app with Microsoft Foundry | [`foundry-sdk`](https://learn.microsoft.com/en-us/training/modules/foundry-sdk/) | [03-foundry-sdk](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/03-foundry-sdk.html) | L300, 45 分鐘 | 優先講清 endpoint / SDK 與 Responses API |
| M04 | Develop generative AI apps that use tools | [`use-generative-ai-tools`](https://learn.microsoft.com/en-us/training/modules/use-generative-ai-tools/) | [04a-use-own-data](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/04a-use-own-data.html) | L300, 30 分鐘 | 以 `file_search` 和 function orchestration 為重點 |
| M05 | Optimize generative AI model performance with Microsoft Foundry | [`optimize-generative-ai-model-performance`](https://learn.microsoft.com/en-us/training/modules/optimize-generative-ai-model-performance/) | [04b-finetune-model](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/04b-finetune-model.html) | L300, 90 分鐘 | lab 的 `gpt-5` SFT 路徑高風險；必須預建備援 |
| M06 | Implement a responsible generative AI solution in Microsoft Foundry | [`responsible-ai-studio`](https://learn.microsoft.com/en-us/training/modules/responsible-ai-studio/) | [06-Explore-content-filters](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/06-Explore-content-filters.html) | L300, 25 分鐘 | 以多層防禦與 guardrail 概念收束 |
| M07 | Develop AI agents with Microsoft Foundry and Visual Studio Code | [`develop-ai-agents-azure-vs-code`](https://learn.microsoft.com/en-us/training/modules/develop-ai-agents-azure-vs-code/) **（standalone）** | [01-build-agent-portal-and-vscode](https://microsoftlearning.github.io/mslearn-ai-agents/Instructions/Exercises/01-build-agent-portal-and-vscode.html) | 未列入 M01–M06 時間 | 視時間採 portal demo 或 VS Code 延伸 |

### 版本與品牌速查
| 舊名稱 / 舊素材可能出現的文字 | 本課應使用的名稱 | 對學員的說法 |
|---|---|---|
| Cognitive Services | Foundry Tools | 「這是同一脈絡的 pre-built AI capabilities，名稱隨平台整合演進。」 |
| Azure AI Services | Foundry Tools | 「目前課程採用 Foundry Tools 品牌。」 |
| Azure AI Studio | Microsoft Foundry | 「若文件或舊截圖寫 Azure AI Studio，請以 Microsoft Foundry portal 的現行介面操作。」 |
| Azure AI Foundry | Microsoft Foundry | 「December 2025 後課程改用 Microsoft Foundry 品牌。」 |
| `Prompt Flow` | 不在本課 | 「May 2025 已從 AI-3016 移除；今天不把它當成課程目標。」 |
---

## 3. 建議議程與時間分配

### 先說明現實限制
M01–M06 的官方 lab 建議時間合計為 **265 分鐘**：
| Lab | 建議時間 |
|---|---:|
| M01 | 30 分鐘 |
| M02 | 45 分鐘 |
| M03 | 45 分鐘 |
| M04 | 30 分鐘 |
| M05 | 90 分鐘 |
| M06 | 25 分鐘 |
| **合計** | **265 分鐘（4 小時 25 分鐘）** |
若再加上七個 lesson 的講解、開場、兩次 break、lunch 與 M07，無法在正常的一天內讓所有人
完整做完所有 lab。Trainer Prep Guide 也指出投影片刻意只選取 Learn 的部分內容，且雲端服務的
網路、容量、配額與 UI 變化都會影響實作時間。
**建議方案：保留 M02、M03、M04、M06 的核心實作；M01 依班級熟悉度縮為 demo；M05 使用預建
micro-tuning 成果與講師操作，讓學員了解流程但不等待非同步訓練；M07 作為 20–30 分鐘 portal demo
或課後獨立 lab。** 這是最能同時保留互動、避免微調阻塞、符合一天課程定位的方案。
| 方案 | 優點 | 缺點 | 建議 |
|---|---|---|---|
| 全數逐步做完 | 每個 lab 都有親手操作 | 時間明顯不足；M05 可能卡 60+ 分鐘；體驗容易被等待破壞 | 不建議 |
| **核心 lab + 預建 M05 / M07 demo** | 保留最多可立即回饋的操作；可涵蓋完整課程地圖 | 學員不會完成每個微調或 agent 步驟 | **建議採用** |
| 以投影片為主、少做 labs | 節奏看似可控 | 違反 labs 是主要學習載體的設計；學員帶不走操作經驗 | 不建議 |

### 建議一天議程（約 6.5 小時教學）
| 時間 | 活動 | 講師操作與取捨 |
|---|---|---|
| 09:00–09:20 | 開場、登入、課程地圖 | 確認 hosted lab 可用；介紹 workload scope、M01–M07 與今日節奏 |
| 09:20–09:55 | M01：Foundry mental model + portal | 10–15 分鐘講解；熟悉班級只 demo project / model / endpoint |
| 09:55–10:10 | Break | 講師確認落後學員登入與資源建立狀態 |
| 10:10–11:00 | M02：模型型錄、部署、評估 | 先講比較框架，再讓學員跑模型比較；保留一份預先完成 evaluation 當備援 |
| 11:00–11:50 | M03：endpoint、SDK、Responses API | 用比較表解釋，再完成 chat app 核心路徑 |
| 11:50–12:00 | M03 知識檢核與緩衝 | 不逐字讀程式；針對 endpoint 混淆再講一次 |
| 12:00–13:00 | Lunch | 重新開啟 M04 與 M06 portal 頁面；檢查 backup environment |
| 13:00–13:45 | M04：tools 與 own data | `file_search`、`code_interpreter`、function orchestration；視情況縮減 web search 現場等待 |
| 13:45–14:05 | M05：prompt / RAG / fine-tuning 決策 | 用「知識不足 vs 行為不一致」診斷；展示 prebuilt fine-tune job / deployment |
| 14:05–14:20 | Break | 讓學員完成 M04；講師切換到 guarded deployment |
| 14:20–14:50 | M05：微調風險與成果 demo | 說明 lab `gpt-5` SFT 限制，使用 `gpt-4.1-mini` 備援成果 |
| 14:50–15:30 | M06：Responsible AI 與 guardrails | 用分層防禦、Impact Assessment、custom guardrail 收束 |
| 15:30–16:15 | M07：agent portal / VS Code demo | 有時間才進 VS Code；否則 portal demo 後提供 standalone module |
| 16:15–17:00 | 回顧、Q&A、課後路徑 | 對齊 Achievement Code、AI-103 範圍與 Learn 延伸；處理落後學員與延伸問題 |

### 時間救援規則
若時間落後 15 分鐘：
1. M01 不讓每位學員重做完整操作，改由講師示範 project、deployment 與 endpoint。
2. M02 保留 model choice / evaluation 概念，但不等待每組 synthetic evaluation 完成。
3. M04 只完整示範一條 `file_search` 路徑；用投影片解釋 `web_search` 與 `code_interpreter`。
4. M05 絕不等待當天 fine-tuning；只展示已完成的 job、model 與 Developer deployment。
5. M07 不犧牲 M06；改成 portal demo + 課後 standalone lab link。
若時間落後 30 分鐘以上：
- 宣告改採「講師 live demo + 學員課後完成」模式，而不是讓全班無限等待。
- 優先保留 M03、M04、M06，因為它們最直接呈現 app 開發、tool orchestration 與安全責任。
- 把 M02 的 leaderboard、M05 的完整 UI 路徑與 M07 的 VS Code setup 交給 Learn 及課後 lab。
---

## 4. 貫穿全課的核心觀念

### 4.1 Azure AI workload map：先定義今天不教什麼
投影片 2–3 的目的不是列名詞，而是管理期待。可用以下話術：
> 「Azure AI 有 Text and Language、Computer Speech、Computer Vision、Information Extraction、
> Machine Learning 等工作負載。今天聚焦 **Generative AI and Agents**：模型如何回應、如何接資料、
> 如何用 tools 行動，以及如何安全地把它們放進應用程式。」
將 classic ML 與 generative AI 做快速對照：
| 面向 | Classic ML | Generative AI |
|---|---|---|
| 常見目的 | 根據特徵預測分類或數值 | 產生、推理、對話、摘要、程式與內容 |
| 心智模型 | `f(x)=y` | prompt + context + model + tools → response |
| 今天的重點 | 不是模型訓練演算法 | app orchestration、model selection、grounding、安全與 agents |

### 4.2 Microsoft Foundry mental model
把下表當成本課「迷路時的地圖」。投影片講者備註的核心提醒是：**當學員感到混亂，就帶回這張圖。**
| 層級 | 是什麼 | 講師該強調的事 |
|---|---|---|
| Foundry resources | Azure 中提供 compute、storage、model delivery 與其他 services 的資源 | resource 是能力與容量的承載層，不等於某個 app |
| Foundry projects | app / agent 開發的隔離工作環境 | 每個 lab 建新 project 是刻意的隔離與模組化，不是操作失誤 |
| Models | 從 model catalog 選擇並部署的模型 | 先定需求與評估，再選模型；不要只看「最新」 |
| Agents | 使用 model 做語言、推理與行動的可管理實體 | agent 不只是 chat；它結合 instructions、tools 與 state |
| Tools | 讓 model 可存取資訊或採取行動的能力 | model 選擇何時呼叫；應用程式控制允許哪些能力與執行邊界 |
| Knowledge | agents 可存取的資料來源 | grounding 讓回應依據資料，而不是憑模型既有知識猜測 |
可用的一句話：
> 「資源提供能力，project 隔離工作；在 project 裡，我們用 Models、Agents、Tools、Knowledge
> 組出解決方案。」

### 4.3 命名歷史：避免把品牌變更當成不同產品
| 時期 | 名稱 | 今日說法 |
|---|---|---|
| 較早期 | Cognitive Services | Foundry Tools 的前身名稱 |
| 中期 | Azure AI Services | 同一脈絡的 pre-built capabilities |
| 較早 portal | Azure AI Studio | 已演進至 Microsoft Foundry |
| 2024–2025 | Azure AI Foundry | 已重新品牌為 Microsoft Foundry |
| 現行課程 | Foundry Tools / Microsoft Foundry | 教學與文件一律採此名稱 |
避免花太多時間在命名史；它的用途是幫學員閱讀舊文件時能正確對照，而不是成為考試題。

### 4.4 Endpoint choice drives auth and API surface
投影片明確提醒：**在這裡暫停，因為學員最容易混淆 endpoint 與 SDK。**
| 決策面向 | Foundry project endpoint + Foundry SDK | Azure OpenAI endpoint + OpenAI SDK |
|---|---|---|
| Endpoint 形狀 | `https://{resource-name}.services.ai.azure.com/api/projects/{project-name}` | `https://{resource-name}.openai.azure.com/openai/v1` |
| 主要 SDK | `azure-ai-projects` 與 `openai` | `openai` |
| 驗證 | Microsoft Entra ID | Microsoft Entra ID 或 API key |
| API | Foundry direct models 的 Responses API | Responses API 或 ChatCompletions API，OpenAI API surface 較完整 |
| 適合情境 | Foundry-native project operations、project 資產與相容介面 | 最新 OpenAI SDK features、最廣的 OpenAI API 支援與模型範圍 |
| 話術 | 「我需要 project 的 Foundry 能力。」 | 「我需要完整的 OpenAI API surface。」 |
不要讓學員背 endpoint 字串；請他們先回答：「我選哪一個 endpoint，就同時選定了哪種 auth
與 API surface？」這才是可遷移的技能。

### 4.5 ChatCompletions vs Responses API
投影片的結論：**除非需要自訂 memory handling，否則新 app 優先採 Responses API。**
| 面向 | ChatCompletions API | Responses API |
|---|---|---|
| 對話 state | client-side；開發者保存並送出完整 `messages` array | server-side；API 自動管理 conversation context |
| 系統行為 | `messages` 的第一筆 `{"role": "system", "content": "..."}` | 專用 `instructions="..."` 參數 |
| 每回合 payload | 對話越長越大 | 只送最新 `input` 與前一回合 ID，接近固定 |
| 請求方法 | `client.chat.completions.create()` | `client.responses.create()` |
| 取得文字 | `completion.choices[0].message.content` | `response.output_text` |
| 多回合關鍵 | 自己 append user / assistant message | 傳入 `previous_response_id` |
| 取捨 | memory 完全由 app 控制，但複雜度與 token payload 較高 | state 管理較簡潔，是較新的建議模式 |
講解程式碼時，一次只要求學員看到三件事：
```python
response = openai_client.responses.create(
    model=os.environ["MODEL_DEPLOYMENT"],
    instructions="You are a helpful AI assistant that explains technology concepts.",
    input=input_text,
    previous_response_id=last_response_id,
)
assistant_text = response.output_text
last_response_id = response.id
```
- `instructions` 定義行為，而非永久訓練資料。
- `previous_response_id` 延續對話。
- `response.output_text` 是 SDK 的便利輸出。
> [!TIP]
> 投影片程式碼在 slides 22/23/24/32/36 硬寫 `gpt-4.1`，但現行 labs 部署 `gpt-5.2`。
> 講師示範程式應讀取 `MODEL_DEPLOYMENT` 環境變數，並口頭說明投影片與 lab 的版本落差；
> 不要把新模型部署成名為 `gpt-4.1` 的 deployment 來假裝一致。

### 4.6 Model lifecycle：每次授課前重新查
| 模型 | 狀態與日期 | 本課教學判斷 |
|---|---|---|
| `gpt-5.2`（2025-12-11） | **GA**；retire 2027-06-08 | M01、M03、M04、M06 lab 使用；目前安全，但仍要重查 |
| `gpt-5`、`gpt-5-mini`（2025-08-07） | GA；retire 2027-02-09；2026-08-07 後新客戶不可建立 deployment | M02 與 M05 需以實際 subscription 預檢，不能假設可用 |
| `gpt-4.1` / `gpt-4.1-mini`（2025-04-14） | **Legacy**；retire 2027-04-14 | 仍可部署；`gpt-4.1-mini` 是 M05 SFT 備援，但有到期風險 |
| `gpt-4o`、`gpt-4o-mini`、`o1`、`o3-mini`、`o4-mini` | **Deprecated**；`o4-mini` retire 2026-10-16 | 不可用於新 subscription 的課程備援 |
| `gpt-5-chat`、`gpt-5.1-chat`、`gpt-5.2-chat`、`gpt-5.3-chat` | **Retired** | 不可使用 |
`gpt-5` 與 `gpt-5-mini` 的「existing customer」由**每個 Azure subscription**判定。新 subscription
不會繼承同 tenant 中另一 subscription 的部署資格。Skillable lab subscription 與講師訂閱是不同
subscription，因此必須對兩者都測試。

### 4.7 為何每個 exercise 都建立新 Foundry project
請在第一個 exercise 前先說明：
> 「你們今天會很熟悉建立 project 的步驟。這不是重複設計失誤，而是 labs 必須可獨立重用，
> 也要避免不必要地持續佔用 Azure 成本與資料中心容量。」
Trainer Prep Guide 的補充理由：
- labs 要能被不同 delivery modality 重用與客製。
- 單一共享環境在實務上成本與 capacity utilization 較高。
- 各 feature 的 region / model availability 不同，某一 lab 建立的資源不一定能安全重用。
- 重複建立有助於每個 exercise 都有清楚的起點與清理邊界。

### 4.8 講師 demo environment：Entra ID only 與備援定位
`TERRAFORM/` 是講師的 backup environment，不是學員的 lab，也不是課中才按下的 emergency switch。
| 設計 | 說明 | 教學價值 |
|---|---|---|
| 區域 | `swedencentral` | 同時符合 Lab 04b 區域、完整 Agent tool matrix、`gpt-4.1` fine-tuning standard region 與全課模型 Global Standard |
| 驗證 | Entra ID（AAD）only | Storage shared keys disabled，Foundry `local_auth_enabled = false` |
| 授權 | managed identity + RBAC | 可示範 production-minded 的 key-less 設計 |
| 已預建 | `gpt-5.2`、`gpt-5-mini`、`gpt-4.1-mini`、guarded deployment、vector store、demo agent | 遇到 quota / UI / 非同步問題時可繼續教學 |
| 不能預建 | live model catalog / leaderboard、agent conversation、Code Interpreter session、VS Code workstation | 當天仍要開啟並 smoke test |
> [!WARNING]
> 微調需要 60+ 分鐘，部署與 RBAC 也可能非同步。備援環境必須於課前 **1–2 天**建立、
> smoke test，授課期間保持運作，課後才 `terraform destroy`。
---

## 5. 逐模組備課指南

### M01 — Plan and prepare to develop AI solutions on Azure
#### 學習目標
- 說明 Microsoft Foundry resources、projects、Models、Agents、Tools、Knowledge 的關係。
- 辨識 Foundry Tools 與前身 Azure AI Services / Cognitive Services 的命名關係。
- 說明 developer tools、SDKs 與 Responsible AI 的基本位置。
- 能在 Microsoft Foundry portal 建立 project、部署模型、找到 endpoint，並認識 VS Code extension。
#### 講解重點
- 先用 workload map 界定今日只談 Generative AI and Agents；vision、speech、translation 等屬 Azure AI
  範圍，但不是今日深度主題。
- 用「resources 提供能力、projects 隔離工作」說明 Foundry。學員找不到功能時，帶回
  Models / Agents / Tools / Knowledge 四格心智模型。
- 說明 Foundry Tools 是 pre-built capabilities，不是要模型重新發明的能力；可串接 language、
  speech、translator、document intelligence 與 content understanding。
- 描述工作流程為「portal playground 先驗證」與「code-first 用 SDK 開發」兩條路，兩者可並存。
- 談 Responsible AI 時只種下伏筆：fairness、reliability & safety、privacy & security、
  inclusiveness、transparency、accountability 都會落到 data、prompt、guardrail、UX 與 operations。
- 講者備註的節奏提示：若學員已相當熟悉，**可跳過 M01 完整 lab，只 demo portal**，把時間保留給
  M03–M06。
#### Demo / Lab 連結
| 用途 | 連結 | 講師操作 |
|---|---|---|
| Learn module | [Plan and prepare to develop AI solutions on Azure](https://learn.microsoft.com/en-us/training/modules/prepare-azure-ai-development/) | 課前複習完整單元；課後讓學員延伸 |
| Exercise | [01-Explore-ai-studio](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/01-Explore-ai-studio.html) | 建 project、部署並測試模型、找 endpoint/key、看 VS Code extension |
| Lab index | [mslearn-ai-studio](https://microsoftlearning.github.io/mslearn-ai-studio/) | UI 不同時由 index 導回現行說明 |
建議 live demo 順序：
1. 從 Microsoft Foundry portal 指出 resource 與 project。
2. 在 project 中指向 Models、Agents、Tools、Knowledge 的導覽位置。
3. 開啟已部署模型的 playground，送一個簡短 prompt。
4. 指出 endpoint 資訊是後續 SDK 選擇的起點，不在此處深挖 API。
5. 展示 VS Code 的 Microsoft AI Toolkit extension 名稱與用途，不花時間完成完整 workstation setup。
#### 常見問題 / 坑
| 情況 | 講師處置 |
|---|---|
| 學員問 Foundry resource 與 project 是否相同 | 否。resource 是 Azure 能力承載；project 是隔離的 app / agent 工作區。 |
| 學員在舊文件看到 Azure AI Studio | 說明品牌已演進至 Microsoft Foundry，功能以現行 portal 為準。 |
| 學員卡在重複建立 project | 預先說明 modularity、成本與 regional availability 理由；不要把它描述為不必要步驟。 |
| 學員花太久探索 extension | 停在「能找到 extension、知道它支援 Foundry project」；M07 再做 code-first。 |
| UI 與 lab 截圖不同 | 先辨識目標功能，再請學員比對名稱與導覽；重大不一致應回報 `mslearn-ai-studio` repo issue。 |
**Knowledge check 正解**
1. 用來處理 Foundry project assets 的 portal：**The Microsoft Foundry portal**。
2. 提供常見 AI task pre-built services 的元件：**Foundry Tools**。
3. 在 Visual Studio Code 使用的 extension：**Microsoft AI Toolkit extension for Visual Studio Code**。
#### 重要連結
- [Microsoft Foundry Learn module](https://learn.microsoft.com/en-us/training/modules/prepare-azure-ai-development/)
- [Microsoft Learn profile](https://learn.microsoft.com/)
- [M01 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/01-Explore-ai-studio.html)
---

### M02 — Select, deploy, and evaluate Microsoft Foundry Models
#### 學習目標
- 使用 model catalog 的 collections、capabilities、provider、inference tasks、fine-tuning support、
  industry 等篩選條件。
- 以 quality、safety、throughput、cost 的 benchmark 指標做選型。
- 辨識 Global Standard、Global Provisioned、Global Batch、Data Zone、Standard 與 Developer 的用途。
- 在 playground、side-by-side comparison 與 automated evaluation 間建立評估流程。
#### 講解重點
- 先教選型策略：**先看 curated collections / capabilities，再看 provider 與 task，最後才看
  fine-tuning support**。這可避免從所有模型清單盲目開始。
- model choice 是迭代工作。先選 baseline，快速在 playground 驗證，再用代表性 prompts 與 edge prompts
  檢驗，而不是一次選出「完美模型」。
- 講 benchmark 時，將指標翻成 app 後果：Quality index 是回應有用性；attack success rate 是對 prompt
  attacks 的韌性；throughput 是負載下的反應速度；cost 是每百萬 token 的經濟性。
- deployment type 的速記：一般工作負載與最大 quota 選 **Global Standard**；穩定高 throughput 選
  Provisioned；大量非同步選 Batch；EU/US data zone 需求選 Data Zone；regional compliance / low volume
  選 Standard；fine-tuned model evaluation 選 Developer。
- manual evaluation 是 playground 的代表性 prompt 與 side-by-side；automated evaluation 則用 synthetic
  dataset 或自有資料集搭配標準 metrics。兩者都需要。
- 不要承諾 leaderboard 排名固定。catalog 與 leaderboard 是 live portal content，無法由 Terraform 預建。
#### Demo / Lab 連結
| 用途 | 連結 | 講師操作 |
|---|---|---|
| Learn module | [Select, deploy, and evaluate Microsoft Foundry Models](https://learn.microsoft.com/en-us/training/modules/model-catalog-evaluate/) | 用於選型與 evaluation 延伸 |
| Exercise | [02-model-catalog-evaluation](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/02-model-catalog-evaluation.html) | catalog、leaderboard、deployment、playground、synthetic evaluation |
| M02 lab fallback | [Demo environment](demo-environment.md) | 展示備援的 `gpt-5.2` / `gpt-5-mini` deployment |
建議示範提問：
> 「如果我們的約束是一般 chat workload、希望 quota 最大、暫時沒有 data residency 限制，
> 你會從哪一種 deployment type 開始？答案不是『所有選項都試一次』，而是 Global Standard。」
#### 常見問題 / 坑
| 情況 | 講師處置 |
|---|---|
| 學員用「品質最高」取代所有選型判斷 | 要他同時考量 safety、throughput、cost、region、deployment type 與需求。 |
| leaderboard 與投影片或同學畫面不同 | 正常；它是即時 portal content。教比較框架，不教固定名次。 |
| `gpt-5-mini` 不能部署 | 先確認 subscription；它在 2026-08-07 後受 new customer 規則影響。使用預檢結果與講師備援。 |
| synthetic evaluation 未完成 | 不等待非同步工作。展示預先完成的 evaluation，說明它作為評估流程的證據。 |
| 學員把 Developer 當成一般 production deployment | 釐清 Developer 是 fine-tuned model evaluation only。 |
**Knowledge check 正解**
1. 處理 prompts 並快速回傳回應的 benchmark：**Throughput**。
2. 一般用途且提供最大 quota 的 deployment type：**Global Standard**。
3. 衡量語言正確性與自然語言品質的 metric：**Fluency**。
#### 重要連結
- [Model catalog and evaluation Learn module](https://learn.microsoft.com/en-us/training/modules/model-catalog-evaluate/)
- [M02 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/02-model-catalog-evaluation.html)
- [Model retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)
- [Demo environment model rationale](demo-environment.md)
---

### M03 — Develop a generative AI chat app with Microsoft Foundry
#### 學習目標
- 在 model playground 驗證 prompt、temperature、max tokens 與 system message。
- 區分 Foundry project endpoint + Foundry SDK 與 Azure OpenAI endpoint + OpenAI SDK。
- 比較 ChatCompletions API 與 Responses API 的 state 管理與程式模式。
- 以 Python SDK 建立可持續多回合的 generative AI chat app。
#### 講解重點
- 先示範 playground 是降低「blank page syndrome」的地方：在寫 code 前測 prompt、調整 temperature /
  max tokens、設 system message，並選 API、language、REST 或 SDK sample。
- endpoint 選擇是本段的核心。慢下來講清楚：「**Endpoint choice drives auth and API surface**。」
  學員常把 Foundry project endpoint 的 project client 與 Azure OpenAI endpoint 的 OpenAI client 混在一起。
- 對 Foundry project endpoint，示範 `DefaultAzureCredential` 與 `AIProjectClient`，再從 project client 取得
  OpenAI-compatible client。這是 project-first 工作流。
- 對 Azure OpenAI endpoint，示範 OpenAI SDK 如何指向 `base_url`；它提供更廣的 OpenAI API 支援。
- Responses API 以 `previous_response_id` 交給 server 保存 conversation state；ChatCompletions 以 app 管理
  `messages` history。不是新舊 API 的單純勝負，而是 state ownership 的選擇。
- 用講者備註的總結：除非要 custom memory handling，**新 app 優先 Responses API**。
#### Demo / Lab 連結
| 用途 | 連結 | 講師操作 |
|---|---|---|
| Learn module | [Develop a generative AI chat app with Microsoft Foundry](https://learn.microsoft.com/en-us/training/modules/foundry-sdk/) | SDK 與 endpoint 的課後參考 |
| Exercise | [03-foundry-sdk](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/03-foundry-sdk.html) | 建 project、部署、取得 endpoint / key、寫 chat app |
| 全課 API 對照 | [核心觀念：ChatCompletions vs Responses API](#45-chatcompletions-vs-responses-api) | 投影比較表後再寫 code |
建議 live demo：
1. 在 playground 先送一個相同問題，展示 system message 改變行為。
2. 指出 sample code selector 的 API / language / REST / SDK 選擇。
3. 用 Responses API 寫一回合，再加入 `previous_response_id` 形成兩回合對話。
4. 讓學員觀察第二回合沒有重送整份 `messages` history。
5. 以環境變數取 deployment name，不採用投影片硬寫的 `gpt-4.1`。
#### 常見問題 / 坑
| 情況 | 講師處置 |
|---|---|
| 「Foundry project endpoint 能不能使用所有 OpenAI API？」 | 說明 Azure OpenAI endpoint 提供最廣的 OpenAI API support；先從需求選 endpoint。 |
| 學員把 `previous_response_id` 當成 model deployment | 明確區分：`model` 是 deployment；`previous_response_id` 是前次 response 的 state reference。 |
| 學員忘記更新 `last_response_id` | 對照程式最後兩行：讀 `response.id` 再存到下一回合。 |
| 用錯 response 輸出欄位 | ChatCompletions 用 `completion.choices[0].message.content`；Responses 用 `response.output_text`。 |
| demo 找不到 `gpt-4.1` | 投影片是舊範例；使用 lab 的 `gpt-5.2` 或 `MODEL_DEPLOYMENT`。 |
| endpoint/auth 出現 401 | 先確認選的是 project endpoint 還是 Azure OpenAI endpoint，再確認相對應的 credential 與 RBAC / key。 |
**Knowledge check 正解**
1. 支援最廣 OpenAI APIs 的 endpoint：**The Azure OpenAI endpoint**。
2. Responses API 產生回應的方法：**`client.responses.create()`**。
3. Python 的 Microsoft Foundry SDK package：**`azure-ai-projects`**。
#### 重要連結
- [Foundry SDK Learn module](https://learn.microsoft.com/en-us/training/modules/foundry-sdk/)
- [M03 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/03-foundry-sdk.html)
- [Responses API comparison](#45-chatcompletions-vs-responses-api)
- [Demo environment](demo-environment.md)
---

### M04 — Develop generative AI apps that use tools
#### 學習目標
- 說明 tools 如何讓 model 存取即時資訊、採取動作、ground responses 與延伸 app 功能。
- 使用 `code_interpreter`、`web_search`、`file_search` 與 function tool 的基本模式。
- 說明 managed vector store、檔案 upload / indexing 與 citations。
- 正確實作 function calling：app 執行 function，再送回 `function_call_output`。
#### 講解重點
- 簡短定義：「Tools 讓 model 超出 training cutoff，能取得資訊、執行 code、搜尋文件、呼叫你的 function。」
- 強調 application architecture：model 根據允許的 tools 決定何時呼叫，但**app 是 orchestrator**；
  app 決定提供哪些 tools，並執行自己的 function。
- `code_interpreter`：在 isolated sandbox container 內執行 Python，不是在學員電腦或 app process 上執行。
  `tools` parameter 與 container settings 是明確授權能力的邊界。
- `web_search`：適用需要 current information 的問題，例如 announcements、pricing 或 policy update。
  它的結果會作為 grounding context，並可包含 URLs；不要把它包裝成資料永遠正確的保證。
- `file_search`：vector store 是 managed store；上傳後會自動 chunk 與 embed，查詢時找語意相關 chunks。
  `include=["file_search_call.results"]` 讓結果含 citations，是企業 traceability 的切入點。
- function：最重要的話術是「**model 不會神奇地執行你的 function；是你的程式執行它。**」
  順序是 model 提出 `function_call` → app 執行 → app 傳 `function_call_output` → model 形成使用者回應。
#### Demo / Lab 連結
| 用途 | 連結 | 講師操作 |
|---|---|---|
| Learn module | [Develop generative AI apps that use tools](https://learn.microsoft.com/en-us/training/modules/use-generative-ai-tools/) | 供學員完成完整 tool 範例 |
| Exercise | [04a-use-own-data](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/04a-use-own-data.html) | 以 own data / `file_search` 為主 |
| Fallback vector store | [Demo environment](demo-environment.md) | 顯示預載 6 份 Margie's Travel brochures 的 vector store |
建議 demo 次序：
1. 先示範 `file_search`，讓學員看見「文件 → citations → grounded answer」的完整價值。
2. 再用最簡單的 `get_time` 或 calculator function 講 function orchestration。
3. 示範 `code_interpreter` 求 `sqrt(16)`，並指明 sandboxed runtime。
4. 視網路與時間才做 `web_search`；它無法預建，且 live 結果會改變。
#### 常見問題 / 坑
| 情況 | 講師處置 |
|---|---|
| 學員把 `file_search` 說成所有 RAG 的唯一做法 | 說明它是 managed vector store 的一種實作；核心 RAG pattern 是 retrieve → augment → generate。 |
| 上傳後立刻沒有結果 | 提醒 indexing 可能非同步；使用預建 vector store 作為 fallback。 |
| 學員以為 `code_interpreter` 在本機執行 | 明確說是 model toolchain 的 sandboxed Python runtime。 |
| function call 沒有最終答案 | 確認 app 有執行 function 並把 `function_call_output` 送回 model。 |
| web search 回答與昨天不同 | 這是 current data 的預期結果；教學重點是 tool 選擇與 grounding，不是固定文字。 |
| 只讓 model 呼叫高權限 function | 停下來談最小權限、參數驗證、audit 與 human approval；model output 不是可直接信任的命令。 |
**Knowledge check 正解**
1. 回答自有上傳 policy documents 問題的 tool：**`file_search`**。
2. 收到 `function_call` 後，app 必須：**在自己的 code 執行 function，並將
   `function_call_output` 傳回 model**。
3. `code_interpreter` 的正確描述：**它可在 sandboxed runtime 執行 Python code**。
#### 重要連結
- [Tools Learn module](https://learn.microsoft.com/en-us/training/modules/use-generative-ai-tools/)
- [M04 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/04a-use-own-data.html)
- [M04 fallback environment](demo-environment.md)
---

### M05 — Optimize generative AI model performance with Microsoft Foundry
#### 學習目標
- 區分 context optimization 與 model optimization。
- 用 prompt engineering、RAG、fine-tuning 的目的與成本選擇最佳策略。
- 說明 system message、format template、few-shot learning 與一致性。
- 說明 RAG 的 retrieve → augment → generate 流程。
- 正確定位 fine-tuning：改善 behavior、style、output format 的一致性，不是補齊即時事實。
- 了解 Lab 04b 的 `gpt-5` Supervised fine-tuning 路徑為何目前高風險，以及講師的 `gpt-4.1-mini` 備援。
#### 講解重點
先以診斷問題，而不是技術名詞開始：
| 觀察到的問題 | 優先策略 | 為什麼 |
|---|---|---|
| 回應缺少組織內部、領域或當前資料 | RAG | 問題在「model 不知道什麼」；先擷取正確 context |
| 回應語氣、格式、分類輸出不穩定 | system message / prompt engineering | 問題在「model 要怎麼做」；最低成本且最快迭代 |
| 已有良好 prompts，但仍無法達到穩定行為、style 或 format | fine-tuning | 用高品質 prompt/response examples 改善一致性 |
| 同時需要 current knowledge 與固定輸出格式 | prompt + RAG，必要時再 fine-tuning | 策略可組合，但按最小成本先試 |
講者備註提供的決策順序應明說：
1. 大多數解決方案首先從 prompt engineering 獲益。
2. 有 context-specific data 時使用 RAG。
3. 只有 prompt engineering 無法取得需要的 tone / style / format consistency 時才考慮 fine-tuning。
4. 成本通常由低至高：prompt engineering → RAG（storage / index）→ fine-tuning（training compute）。
可用「錯誤回答 vs 雜亂回答」作為快速診斷：
> 「如果答案是錯的，先問是不是缺 grounding；如果答案是雜亂或不一致，先收緊 prompt，
> 再評估是否真的需要 fine-tuning。」
Prompt engineering 的講法：
- system message 是 **role + behavior constraints + output format expectations**。
- format template pattern 用於可預期的輸出欄位。
- few-shot learning 用於分類或抽取的一致性。
- 對 chain-of-thought 類的示例，聚焦於「要求結構化推理與可驗證輸出」，不要把課堂變成揭露內部推理的討論。
- 用同一個問題的 before / after prompt 快速展示，而不要長時間朗讀範例 prompt。
RAG 的講法：
1. 接收 user input。
2. 依 input 從 vector-based index retrieve 相關資料。
3. 將 search results augment 到 prompt。
4. model 用 grounding context 產生回應。
Fine-tuning 的講法：
- 輸入是 foundation model 與 prompt / preferred response examples。
- 輸出是更一致地遵守 tone、style、output structure 的 fine-tuned model。
- 它不是把文件資料永久塞進模型，也不是取代 current data 的 RAG。
- Lab 04b 的實際可用性問題見本文件的[專節](#6-lab-04b-微調專節)；不要在教室才發現。
#### Demo / Lab 連結
| 用途 | 連結 | 講師操作 |
|---|---|---|
| Learn module | [Optimize generative AI model performance](https://learn.microsoft.com/en-us/training/modules/optimize-generative-ai-model-performance/) | 課後延伸完整內容 |
| Exercise | [04b-finetune-model](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/04b-finetune-model.html) | 說明官方 lab 路徑與目前風險 |
| 微調操作 | [TERRAFORM README](../TERRAFORM/README.md) | 課前執行 `Start-FineTune.ps1`，展示已完成結果 |
| 完整風險處置 | [Lab 04b 微調專節](#6-lab-04b-微調專節) | 授課前讀完並依預檢結果選定方案 |
推薦課中操作：
1. 現場做一個 2 分鐘 before / after system prompt。
2. 用 M04 的 `file_search` 回扣 RAG，說明它正是 context optimization 的實例。
3. 顯示已完成的 fine-tuning job、training data 格式與 Developer deployment。
4. 明確說明今天不等待訓練：時間長與非同步本來就是 production reality。
5. 若 lab 資源支援，讓學員走到提交 job 的前一階段；如果 `gpt-5` SFT 被阻擋，立即轉備援方案，不花時間反覆重試。
#### 常見問題 / 坑
| 情況 | 講師處置 |
|---|---|
| 「fine-tuning 可以讓模型知道最新公司政策嗎？」 | 否。current / domain-specific facts 優先用 RAG；fine-tuning 針對行為、風格、格式一致性。 |
| 「只要寫 system message 就不需要 RAG？」 | 不對。system message 控制行為，不能提供模型未知的可靠 current context。 |
| 學員想直接微調來解決所有問題 | 用成本與診斷表回應；先 prompt，必要時 RAG，最後才 fine-tuning。 |
| `gpt-5` Supervised 選項不可用或被拒絕 | 這是預期風險，不是學員錯誤。使用 `gpt-4.1-mini` 備援，詳細見專節。 |
| full `gpt-4.1` quota 不足 | 測試訂閱為 3075/3075 已用盡；採用 `gpt-4.1-mini`。 |
| 學員想在上課最後才開始 training | 不可。需在課前 1–2 天執行；fine-tuning 可超過 60 分鐘。 |
| 2027 年後還可照用 `gpt-4.1-mini` 嗎 | 不可保證；整個 `gpt-4.1` family retire 2027-04-14。 |
**Knowledge check 正解**
1. system message 的主要目的：**define the model's role, behavior, and output constraints**。
2. 何時用 RAG 而非只靠 prompt engineering：**當 model 需要其未受訓的 domain-specific 或 current data**。
3. fine-tuning 最佳化的是：**model behavior、style 與 output format 的 consistency**。
#### 重要連結
- [Optimization Learn module](https://learn.microsoft.com/en-us/training/modules/optimize-generative-ai-model-performance/)
- [M05 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/04b-finetune-model.html)
- [Fine-tuning support table](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure?pivots=azure-openai#fine-tuning-models)
- [TERRAFORM fine-tuning procedure](../TERRAFORM/README.md)
- [M05 dedicated workaround](#6-lab-04b-微調專節)
---

### M06 — Implement a responsible generative AI solution in Microsoft Foundry
#### 學習目標
- 說明 Map、Measure、Mitigate、Manage 的 Responsible AI lifecycle。
- 使用 AI Impact Assessment 記錄目的、預期使用方式與潛在傷害。
- 說明 model、safety system、system message / grounding、user experience 的多層防禦。
- 認識 Foundry Guardrails 能處理的 harmful content、prompt attacks、indirect attacks、groundedness 與 PII。
- 在 portal 探索 default guardrail 與 custom guardrail。
#### 講解重點
用四個動詞帶過全段：
| 動詞 | 講師說法 | 證據 / 產物 |
|---|---|---|
| Map | 「先列出這個 use case 會造成哪些 harms。」 | 風險地圖、AI Impact Assessment |
| Measure | 「再測量這些 harms 是否出現在真實輸出。」 | 測試 prompts、evaluation、觀察資料 |
| Mitigate | 「防護不是單一 toggle，而是多層控制。」 | model、safety system、prompt / grounding、UX controls |
| Manage | 「部署後仍要管理，逐步推出並監測。」 | readiness plan、phased delivery、feedback loop |
講 guardrails 時避免逐條背定義；將風險放入 app 情境：
- violence、hate、sexual content、self-harm：harmful content categories。
- user prompt attacks：使用者試圖改寫 system rules。
- indirect attacks：惡意指令埋在被檢索的外部文件中。
- spotlighting：處理第三方文件時，加強對 indirect attacks 的保護。
- protected material for code / text：識別可能與已知內容匹配的輸出。
- groundedness：檢查生成內容是否與引用 source 對齊。
- PII：辨識姓名、地址、聯絡資料等敏感暴露。
講者備註的關鍵：**mitigation is not one toggle**。這一點可回扣 M04 的 RAG / tools：
tools 與 grounded data 增加能力，也增加 prompt injection 與資料邊界風險。
#### Demo / Lab 連結
| 用途 | 連結 | 講師操作 |
|---|---|---|
| Learn module | [Implement a responsible generative AI solution](https://learn.microsoft.com/en-us/training/modules/responsible-ai-studio/) | 課後完成 Impact Assessment 與責任設計延伸 |
| Exercise | [06-Explore-content-filters](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/06-Explore-content-filters.html) | default guardrail、custom guardrail |
| Guarded fallback | [Demo environment](demo-environment.md) | 顯示獨立 `gpt-5.2-guarded` deployment 與 strict custom guardrail |
| Impact Assessment | [Microsoft Responsible AI Impact Assessment template](https://msblogs.thesourcemediaassets.com/sites/5/2022/06/Microsoft-RAI-Impact-Assessment-Template.pdf) | 說明文件化目的，不要當法律免責文件 |
示範注意：
- `gpt-5.2-guarded` 是**獨立 deployment**，嚴格 thresholds 不影響 M01/M03/M04 的主 demo。
- 特定 prompt 是否被 block 可能具機率性；請展示「guardrail 已掛上」與設計理由，不要承諾固定一句話
  一定被阻擋。
- 對 harmful content 不需要朗讀或展示過度刺激的內容；選擇安全、抽象、符合 lab 的測試情境。
#### 常見問題 / 坑
| 情況 | 講師處置 |
|---|---|
| 「開啟 guardrail 後就完全安全嗎？」 | 否。需 Map、Measure、Mitigate、Manage，並在 model、safety system、prompt / grounding、UX 分層處理。 |
| 「Impact Assessment 是法律免責嗎？」 | 否。它記錄 purpose、expected use、potential harms 與 mitigations。 |
| 有 RAG 就不會受到 injection | 不對。grounded documents 也可能有 indirect attacks；需使用 multi-layer controls。 |
| custom guardrail 影響前面 chat demo | 不應影響；備援環境刻意將 strict policy 放在 `gpt-5.2-guarded`。 |
| 某次 response 沒被 block | 說明 block 行為不宜以單一提示承諾；檢查 policy、threshold、測試集與量測。 |
**Knowledge check 正解**
1. 建立 AI Impact Assessment 的原因：**document the purpose, expected use, and potential harms**。
2. 在 Safety System 層級 mitigating harmful content 的 capability：**Guardrails**。
3. 採 phased delivery plan 的原因：**gather feedback and identify issues before releasing more broadly**。
#### 重要連結
- [Responsible AI Learn module](https://learn.microsoft.com/en-us/training/modules/responsible-ai-studio/)
- [M06 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/06-Explore-content-filters.html)
- [Responsible AI Impact Assessment template](https://msblogs.thesourcemediaassets.com/sites/5/2022/06/Microsoft-RAI-Impact-Assessment-Template.pdf)
- [Demo environment guarded deployment](demo-environment.md)
---

### M07 — Develop AI agents with Microsoft Foundry and Visual Studio Code
#### 學習目標
- 定義 agent 為 LLM、instructions、tools、input、output 與 state 的協作。
- 描述 agent 在 productivity、research、sales、customer service 的適用情境與風險。
- 說明 Foundry Agent Service 協助處理 tool calling、state management 與 infrastructure。
- 比較 Foundry portal 的 visual prototyping 與 Visual Studio Code 的 code-first、Git-friendly workflow。
- 在 portal 與 VS Code 建立、測試、迭代 agent 的基本流程。
#### 講解重點
M07 是 standalone module，不在 `develop-generative-ai-apps` learning path。請清楚講：
> 「這是今天第七個 lesson，但它使用另一個獨立 Learn module 與另一個 lab repo；完成它後，
> 你會把前面 Models、Tools、Knowledge 的概念收斂到 agent。」
用 agent 的三個元件講解：
| 元件 | 內容 | 講師提醒 |
|---|---|---|
| LLM | GPT、Llama、Mistral、Claude 等可用 model | model 是 reasoning / language engine，但不是完整 agent |
| Instructions | role、約束、流程與決策規則 | 例：先確認 trip dates 與 budget，再進行 booking |
| Tools | retrieval、actions、memory 等能力 | 工具擴大 agent 能力，也引入權限與安全邊界 |
典型開發流程：
1. Connect to Foundry project。
2. Create AI agent。
3. Configure agent instructions。
4. Add tools。
5. 在 playground test。
6. Iterate on design。
7. Deploy to production。
8. Integrate into applications。
portal 與 VS Code 的取捨：
| 方式 | 優點 | 適合何時 |
|---|---|---|
| Foundry portal | 無需 local setup、visual configuration、快速 prototype、集中管理、利於非工程 stakeholder 協作 | 第一次理解 agent / 快速驗證概念 |
| Visual Studio Code | code-first、YAML、version control、與 app code 共存、local development | 工程化、團隊協作、可重現設定 |
不要承諾 agent conversation 或 Code Interpreter session 可由備援環境保持「暖機」。它們無法保溫，
必須在授課當天重新開啟並 smoke test。
#### Demo / Lab 連結
| 用途 | 連結 | 講師操作 |
|---|---|---|
| Standalone Learn module | [Develop AI agents with Microsoft Foundry and Visual Studio Code](https://learn.microsoft.com/en-us/training/modules/develop-ai-agents-azure-vs-code/) | 不屬於六模組 learning path；提供課後延伸 |
| M07 lab | [01-build-agent-portal-and-vscode](https://microsoftlearning.github.io/mslearn-ai-agents/Instructions/Exercises/01-build-agent-portal-and-vscode.html) | 使用獨立 `mslearn-ai-agents` repo |
| Fallback agent | [Demo environment](demo-environment.md) | 預建 `file_search` + `code_interpreter` demo agent |
| M07 lab index | [mslearn-ai-agents](https://microsoftlearning.github.io/mslearn-ai-agents/) | 和 M01–M06 repo 分開，授課前確認連結 |
建議示範順序：
1. Portal 建立或開啟 demo agent。
2. 指出 model、instructions、tools、knowledge / files 的設定位置。
3. 問一個能觸發 `file_search` 的問題，再問一個適合 `code_interpreter` 的簡單計算。
4. 顯示 agent 運行後的對話 state，說明 Foundry Agent Service 與 Responses API。
5. 若時間足夠，切到 VS Code 展示 YAML / source control 的開發思路；否則不要在此時做完整環境安裝。
#### 常見問題 / 坑
| 情況 | 講師處置 |
|---|---|
| 「agent 和 chat app 有何不同？」 | agent 將 LLM、instructions、tools、state 與可管理 infrastructure 組合起來，能完成多步工作。 |
| 「agent 會自動安全地執行所有 action 嗎？」 | 否。只提供必要 tools，驗證 parameters，保留 audit / approval；安全責任仍在 app / operator。 |
| 學員找不到 M07 lab | 它在 `mslearn-ai-agents`，不是 `mslearn-ai-studio`。 |
| VS Code setup 花太久 | 先用 portal 完成概念；VS Code 變成課後 standalone module。 |
| Code Interpreter session 不存在 | 正常；session 不可預建或保溫，當日重開並 smoke test。 |
| North Central US 的 Function tool 需求 | 不適合作為全工具 M07 備援；`swedencentral` 才有 File Search、Code Interpreter、Function、Web Search 的完整矩陣。 |
**Knowledge check 正解**
1. Foundry Agent Service 的主要好處：**it handles tool calling, state management, and infrastructure automatically**。
2. agent 的 conversation state 處理方式：**through the Responses API which automatically manages conversation context**。
#### 重要連結
- [M07 standalone Learn module](https://learn.microsoft.com/en-us/training/modules/develop-ai-agents-azure-vs-code/)
- [M07 exercise](https://microsoftlearning.github.io/mslearn-ai-agents/Instructions/Exercises/01-build-agent-portal-and-vscode.html)
- [M07 lab index](https://microsoftlearning.github.io/mslearn-ai-agents/)
- [Demo environment agent fallback](demo-environment.md)
---

## 6. Lab 04b 微調專節
> [!CAUTION]
> ## Lab 04b 很可能依原文失敗
>
> 官方 lab 要求在 `gpt-5` 上執行 **Supervised (SFT)** fine-tuning，使用 Developer deployment，
> 並限制 North Central US 或 Sweden Central。然而官方 fine-tuning support table 對 `gpt-5` 列出的是
> **RFT only**，且標示 GPT-5 reinforcement fine-tuning 雖 GA，但為 **gated and available by invitation only**。
> 這不是一般學員可依 lab 完成的 Supervised 路徑。

### 6.1 原 lab 要求
| Lab 04b 指示 | 原文意義 | 風險 |
|---|---|---|
| Base model `gpt-5` | 以 `gpt-5` 作為微調基底 | `gpt-5` 的 fine-tuning 支援與 lab 的 SFT 指示不相容 |
| Customization method `Supervised` | 執行 SFT | `gpt-5` 只列 RFT，且 gated |
| Deployment type `Developer` | 用於 fine-tuned model evaluation | 正確，但必須基底與微調工作先能建立 |
| Region NCUS / Sweden Central | lab 限制的訓練區域 | 區域本身不解決 method / gated 問題 |

### 6.2 根本原因
- `gpt-5` 在官方支援表中僅有 **RFT**。
- GPT-5 RFT 是 gated，需 invitation；不是可假設人人具備的 lab 前置條件。
- `gpt-5.1`、`gpt-5.2`、`gpt-5.4`、`gpt-5.5`、`gpt-5.6` 都沒有列在 SFT support table。
- 目前沒有同時是**非 Legacy、非 Deprecated**且支援 SFT 的 Azure OpenAI model。
- 所有 SFT-capable 選項都落在 `gpt-4.1` family（Legacy）或 `gpt-4o` family（Deprecated）。

### 6.3 選項比較
| 選項 | SFT | 狀態 / 可用性 | Sweden Central standard fine-tuning | Developer deployment | 與 lab data 相容 | 判定 |
|---|---|---|---|---|---|---|
| Lab 原文 `gpt-5` | **否**；RFT only | RFT gated / invitation only | 是 | 是 | 不適用於原 SFT 步驟 | **不可作為預設課堂方案** |
| `gpt-4.1` | 是 | Legacy；測試 subscription quota 3075/3075 已用盡 | 是 | 是 | 是 | 不建議；配額實務上不足 |
| **`gpt-4.1-mini`** | **是** | Legacy；SFT fine-tuning status GA | **是** | **是** | **是** | **建議方案** |
| `gpt-4o` / `gpt-4o-mini` | 是 | Deprecated | 部分支援 | 是 | 是 | 不可作為新 subscription 的可靠方案 |
| `Llama-3.3-70B-Instruct` | 是 | fine-tuning public preview；Global training only | 否（Global） | 不符合 lab Developer 路徑 | 未作為 lab 直接替代 | `gpt-4.1` 退役後的候選或 explanation-only |

### 6.4 建議方案：`gpt-4.1-mini`
`gpt-4.1-mini` 是目前唯一同時滿足下列條件的實務選擇：
- 支援 **SFT**，fine-tuning status 為 **GA**。
- 基底為 **Legacy** 而非 Deprecated，仍可建立新 deployment。
- 在 `swedencentral` 屬於 standard fine-tuning region。
- 支援 lab 指定的 Developer deployment type。
- 與 `travel-finetune-hotel.jsonl` 的 conversational JSONL training data 完全相容。
- 已於 **2026-08-20** 在 Sweden Central 成功提交 supervised fine-tuning job。
- 完整 `gpt-4.1` 在測試 subscription 無 free Global Standard quota（3075/3075），選 `-mini` 更可靠。
講師對學員的透明說法：
> 「官方 lab 的目的仍是教 Supervised fine-tuning 流程與一致性，不是要你死背某個 model 名稱。
> 目前 `gpt-5` 的 SFT 路徑受官方能力限制；為了在可用的 GA SFT 流程中完成學習目標，
> 我們使用已驗證的 `gpt-4.1-mini` 備援。」

### 6.5 課前必跑的預檢與部署命令
先對**講師 demo subscription**與**新配發的 Skillable subscription**各跑一次 model availability gate：
```powershell
cd TERRAFORM/scripts
./Test-ModelAvailability.ps1
```
建立 backup environment 後，在課前 1–2 天啟動微調：
```powershell
cd TERRAFORM
$ep = terraform output -raw azure_openai_v1_endpoint
$rg = terraform output -raw resource_group_name
$acct = terraform output -raw foundry_account_name
cd scripts
./Start-FineTune.ps1 -Endpoint $ep -ResourceGroup $rg -AccountName $acct -Deploy
```
> [!IMPORTANT]
> 這不是上課才執行的指令。微調需要 **60+ 分鐘**且有非同步步驟；Trainer Prep Guide 也明確要求
> 講師預先準備 fine-tuning demo。執行後確認 job 完成、fine-tuned deployment 可回應，
> 再開始授課。

### 6.6 2027 到期計畫
> [!WARNING]
> 整個 `gpt-4.1` family 會在 **2027-04-14** retire。
>
> 在此日期之後，若 Microsoft 仍未開放 `gpt-5.x` 的 SFT，微調 demo 必須改用
> `Llama-3.3-70B-Instruct`（Global training only，fine-tuning 仍為 public preview），
> 或改成 explanation-only。不能在 2027-04-14 後繼續把 `gpt-4.1-mini` 當作可用備援。
每次課前重新查：
1. `gpt-5.x` 是否已出現在官方 SFT support table。
2. `gpt-4.1-mini` 是否仍未 retirement。
3. 實際 trainer / Skillable subscription 是否有必要 quota 與 Developer tier。
4. `Start-FineTune.ps1` 是否仍能以當前 REST / SDK API 成功完成。
---

## 7. 預期學員問題 Q&A

### Q1：完成這門課有什麼 credential？
**本課只授予 Achievement Code，沒有 Applied Skills credential。** 相關 Applied Skills assessment
已於 **2026-04-15** retired。請引導學員在 Microsoft Learn profile 領取 Achievement Code，而不要承諾
本課可取得仍有效的 Applied Skills。

### Q2：這是 AI-103 的完整考試準備課嗎？
不是。March 2026 的課程更新與 **AI-103 — Microsoft Certified: Azure AI Apps and Agents Developer Associate**
對齊，其認證頁面是：
<https://learn.microsoft.com/en-us/credentials/certifications/azure-ai-apps-and-agents-developer-associate/>
AI-3016 對應的是 AI-103 的**部分** Generative AI / agentic skills。AI-103 還涵蓋 vision、language、
speech、information extraction 等大範圍，本課不能宣稱是 comprehensive AI-103 exam prep。

### Q3：AI-102 呢？
**AI-102 / Azure AI Engineer Associate 已 retired。** 不要把本課描述為 AI-102 備考課，也不要使用舊
AI-102 的 credential 承諾。

### Q4：為什麼每個 lab 都要建立新的 Foundry project？
因為 labs 必須保持獨立、可在不同 delivery modality 重用與客製；重複建立也避免不必要的 Azure
cost 與 capacity usage。不同 feature 的 region / model availability 未必相同，單一共享環境反而可能
讓後續 lab 失敗。投影片講者備註的說法是：學員到一天結束時會很熟悉這個程序。

### Q5：為什麼 slides 寫 `gpt-4.1`，但 lab 要我部署 `gpt-5.2`？
slides 22/23/24/32/36 的 code sample 硬寫 `gpt-4.1`，是教材版本落差；現行 lab 的部署指示是
`gpt-5.2`。請依 lab 部署模型，demo code 讀取 `MODEL_DEPLOYMENT` 環境變數。不要把 deployment
刻意命名成 `gpt-4.1`，因為那會掩蓋版本事實並讓除錯困難。

### Q6：我可以用自己的 Azure subscription 完成 labs 嗎？
可以在課後自行完成，但這門課的 lab 設計是以 hosted lab environment 為主。個人 subscription 會有
不同的 region、quota、role assignment、model lifecycle 與「existing customer」狀態。特別是
`gpt-5` / `gpt-5-mini` 在 2026-08-07 後受每 subscription 的 new customer 限制，個人 subscription
能部署不代表 Skillable 能部署，反之亦然。

### Q7：新的 app 該選 ChatCompletions 還是 Responses API？
預設選 **Responses API**。它讓 server 管理 conversation state，使用 `instructions`、
`response.output_text`、`previous_response_id`，payload 不會隨每輪完整 history 成長。只有你明確需要
custom memory handling、或 endpoint / feature sample 要求時，才優先使用 ChatCompletions。

### Q8：`previous_response_id` 可以永久保存當作使用者記憶嗎？
它用於延續 Responses API 的 conversation context；不要未經架構設計就將其當成產品級 long-term
memory 機制。長期 memory 還涉及 retention、privacy、tenant isolation、retrieval 與刪除需求。

### Q9：`file_search` 是不是等於把資料 fine-tune 到模型？
不是。`file_search` 是以 vector store 找出相關 chunks，在每次請求時提供 grounding context；這是 RAG。
fine-tuning 是以 prompt / response examples 改善模型行為、風格與輸出格式的一致性。

### Q10：為什麼不用 lab 原文的 `gpt-5` 做 SFT？
因為官方 fine-tuning support table 對 `gpt-5` 列的是 gated、invitation-only 的 RFT，不是 lab 寫的
Supervised SFT。講師已驗證 `gpt-4.1-mini` 可在 `swedencentral` 提交 SFT，故使用它作為透明的
課堂備援；完整原因見 [Lab 04b 微調專節](#6-lab-04b-微調專節)。

### Q11：Prompt Flow 去哪了？
**May 2025 已從 AI-3016 移除。** 本課現在聚焦 Microsoft Foundry、Foundry SDK、Responses API、
tools、optimization、Responsible AI 與 agents。若學員找到舊影片或投影片，請視為舊版課程資料，
不要混入今日 lab。

### Q12：guardrail 能保證 model 永遠不產生 harmful content 嗎？
不能。guardrails 是 Safety System 層的控制之一；Responsible AI 要採 Map、Measure、Mitigate、Manage，
並在 model、safety system、system message / grounding、UX 多層防禦。實作上要測量、監控、分階段
推出並保留 human escalation。

### Q13：為何 `code_interpreter` 不該被當成我本機的 Python？
它在 model toolchain 的 sandboxed runtime 執行。它不能取代 app runtime 的安全設計、network policy、
secret management 或 production job scheduler。

### Q14：為什麼講師 backup environment 已建好，但 agent 還要重新測？
agent 的設定、files、tools 可預建；但 agent conversations 與 Code Interpreter sessions 無法保持暖機。
授課當天需重新開啟 session、送小型 prompt、確認 tools 可用。
---

## 8. 課前準備清單（開課前 1–2 天）
> [!WARNING]
> 此清單不是選做。雲端產品、quota、模型 retirements、portal UI 與 SDK 變更都可能使昨天可用的
> lab 在今天失敗。Trainer Prep Guide 要求講師在**每次 delivery 前**親自完成 exercises。

### 8.1 版本、教材與行政
- [ ] 從 MCT Download Center 下載最新版 PowerPoint、Trainer Prep Guide 與 Change Log。
- [ ] 確認使用的教材已包含 March 2026 full refresh 與 May 2026 link / bug fixes。
- [ ] 移除任何 pre-2025 `Prompt Flow`、Azure AI Studio、Azure AI Foundry 的舊話術或截圖。
- [ ] 自訂 Introduction deck 的講師姓名、職稱、經驗、聯絡方式與背景圖。
- [ ] 自訂所有 Exercise slides 的 hosted lab URL 與環境專屬指示，移除投影片中的 trainer arrow / note。
- [ ] 確認 Skillable training key、lab tenant、subscription 與帳號發放方式。
- [ ] 以學員角度開啟 M01–M06 lab index 與 M07 lab index，確認連結仍導向正確 exercise。
- [ ] 重新閱讀每個 Knowledge Check，確認能解釋正解，而不是只記答案。

### 8.2 模型生命週期與 quota 預檢
- [ ] 重新查 [model retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)。
- [ ] 確認 `gpt-5.2` 的 GA status 與 2027-06-08 retirement 未變。
- [ ] 重新確認 `gpt-5` / `gpt-5-mini` 在目標 subscription 的部署資格；不要只看 GA label。
- [ ] 重新確認 `gpt-4.1-mini` 的 SFT 支援與 2027-04-14 retirement 風險。
- [ ] 確認 `gpt-4o`、`gpt-4o-mini`、`o1`、`o3-mini`、`o4-mini` 未被誤列為備援。
- [ ] 確認 retired `gpt-5-chat`、`gpt-5.1-chat`、`gpt-5.2-chat`、`gpt-5.3-chat` 未出現在任何 demo 設定。
- [ ] 對講師 demo subscription 執行預檢：
```powershell
cd TERRAFORM/scripts
./Test-ModelAvailability.ps1
```
- [ ] 對**新配發的 Skillable subscription**執行相同預檢。
- [ ] 若預檢失敗，先決定能否使用既有可用的 lab 路徑；不要在開課時才把未測過的 model 換進教材。

### 8.3 Terraform backup environment
- [ ] 確認 Terraform >= 1.5、PowerShell 7、Azure CLI，並以正確 Entra identity 執行 `az login`。
- [ ] 確認登入身分對目標 subscription 具 Owner 或 Contributor + User Access Administrator。
- [ ] 選擇不重複的 `group_postfix`，例如授課日期 MMDD。
- [ ] 在 `swedencentral` 佈建：
```powershell
cd TERRAFORM
terraform init
terraform plan  -var group_postfix=0821
terraform apply -var group_postfix=0821
```
- [ ] 確認 stack 使用 Entra ID only：Storage shared keys disabled、Foundry `local_auth_enabled = false`。
- [ ] 確認 RBAC propagation 已完成；若初期 401 / 403，等待既有腳本的重試後再判斷。
- [ ] 確認下列 deployment 存在：`gpt-5.2`、`gpt-5-mini`、`gpt-4.1-mini`、`gpt-5.2-guarded`。
- [ ] 確認 strict guardrail 只套用到 `gpt-5.2-guarded`，不影響其他 demo。
- [ ] 確認 vector store 已載入 6 份 Margie's Travel brochures。
- [ ] 確認 demo agent 已具 `file_search` 與 `code_interpreter`。

### 8.4 M05 fine-tuning：必須課前完成
- [ ] 先閱讀本指南的 [Lab 04b 微調專節](#6-lab-04b-微調專節)。
- [ ] 不依賴 `gpt-5` 的 Supervised UI 路徑；預設以 `gpt-4.1-mini` 做 SFT。
- [ ] 執行 `Start-FineTune.ps1`：
```powershell
cd TERRAFORM
$ep = terraform output -raw azure_openai_v1_endpoint
$rg = terraform output -raw resource_group_name
$acct = terraform output -raw foundry_account_name
cd scripts
./Start-FineTune.ps1 -Endpoint $ep -ResourceGroup $rg -AccountName $acct -Deploy
```
- [ ] 等待 60+ 分鐘或直到 job 明確完成；截圖或保留 portal 畫面作為教學備援。
- [ ] 確認 fine-tuned Developer deployment 能完成簡短 prompt。
- [ ] 準備一句透明說明，避免學員以為改模型是隱藏 workaround。

### 8.5 逐模組 smoke test
| 模組 | 課前驗證 |
|---|---|
| M01 | project creation、`gpt-5.2` deployment、playground、endpoint 導覽、VS Code extension 頁面 |
| M02 | model catalog filters、leaderboard 可載入、`gpt-5.2` / `gpt-5-mini` 比較、至少一份已完成 evaluation |
| M03 | `MODEL_DEPLOYMENT` demo code、Responses API、多回合 `previous_response_id` |
| M04 | `file_search` 可回應 brochure 問題、citations、`code_interpreter` 可算 `sqrt(16)`、function output 回傳流程 |
| M05 | `gpt-4.1-mini` SFT job / deployment、training data、prompt vs RAG vs fine-tuning 比較 |
| M06 | default guardrail、custom guardrail、`gpt-5.2-guarded` policy 顯示；不以單一 block 結果作唯一證據 |
| M07 | portal agent、`file_search`、`code_interpreter`；當日也須重開 conversation / session |

### 8.6 Workstation 與投影片
- [ ] 在講師 workstation 安裝 / 更新 VS Code、Python、Azure CLI、Microsoft AI Toolkit extension。
- [ ] 確認 VS Code 已能開啟 M07 所需的 repository / sample，且 Python venv 可運作。
- [ ] 確認 `az login` 指向正確 tenant / subscription；不要在 live demo 時才切帳號。
- [ ] 準備兩種投影畫面：一個 portal、另一個 terminal / VS Code，避免投影切換浪費時間。
- [ ] 將 `MODEL_DEPLOYMENT` 設定為實際 deployment name。
- [ ] 預先開啟參考頁籤：learning path、兩個 lab index、model retirement schedule、fine-tuning support table、
  `TERRAFORM/README.md`、`docs/demo-environment.md`。
---

## 9. 講師小技巧

### 9.1 不要 over-teach 投影片
Trainer Prep Guide 的明確警告：Generative AI 很吸引人，容易讓講師把 presentation 講得過深，
最後沒有足夠時間給 labs。請遵守：
- 不逐字讀 bullet points；學員自己能讀。
- 用投影片說明 **What、Why、How**，再立刻讓學員操作。
- 每個概念只留下能支援下一個 exercise 的最小心智模型。
- 有趣但不影響 learning objective 的架構辯論，停在 parking lot 或課後資源。
- 看到學員已能完成操作，就停止加碼展示，保留時間給下一個 lab。

### 9.2 Live demo 與 pre-built demo 的分界
| 適合 live demo | 適合預建 / fallback |
|---|---|
| Foundry mental model、portal 導覽 | M05 完整 fine-tuning job 與 deployment |
| Playground prompt before / after | M02 已完成 synthetic evaluation |
| Responses API 的 `previous_response_id` | M04 6 份 brochure vector store |
| 簡單 function calling | M06 guarded deployment |
| `file_search` 的一次查詢 | M07 agent 設定與資料 |
| M07 portal agent 入口 | 任何 quota / RBAC / deployment 依賴結果 |
原則：
> **Live demo 要展示決策與可立即回饋的互動；pre-built demo 要吸收非同步、配額與長時間等待。**

### 9.3 讓講者備註變成話術，而不是備註
| 情境 | 可用話術 |
|---|---|
| M01 Foundry | 「如果現在覺得 portal 很多項目，回到 Models、Agents、Tools、Knowledge；大多數工作都能放進其中一格。」 |
| M02 benchmark | 「Benchmark 不完美，但它讓我們不必憑感覺選 model。」 |
| M03 endpoint | 「先選 endpoint，再決定 auth 和 API surface；不要反過來把 SDK code 拼湊在一起。」 |
| M03 Responses | 「`previous_response_id` 是 server-side state 的接力棒；它不是模型名稱。」 |
| M04 function | 「模型提出要呼叫 function，不代表它真的執行了；執行的人是你的 app。」 |
| M04 `code_interpreter` | 「這是 sandbox，不是你的 laptop，也不是 production worker。」 |
| M05 diagnostic | 「答錯先補 knowledge；答得亂先補 behavior。」 |
| M06 safety | 「Guardrail 是一層控制，不是一張免責卡。」 |
| M07 agents | 「Agent 是把 model、instructions、tools 和 state 產品化地串起來。」 |

### 9.4 面對 UI / API 變更
Trainer Prep Guide 建議的處置順序：
1. 確認學員理解 lab 的**目標**，不要只找完全相同的按鈕。
2. 請學員用 product documentation 與現行 UI 推理下一步；這是 cloud-centric 工作的日常技能。
3. 只有確定卡住時才介入，避免立即替所有人點選。
4. 發現 instructions 與現行 UI 重大不符時，在對應 GitHub repo 建 issue，協助 Microsoft 更新 lab。
5. 課中用既有 backup environment 讓其他學員繼續學習，不要讓全班等待單一 UI 問題。

### 9.5 資源與安全邊界
- 不在投影畫面顯示 API key、access token、`.env` 內容或 subscription sensitive data。
- 示範 Entra ID / `DefaultAzureCredential` 時，說明 least privilege 與 RBAC propagation。
- function tool 只示範低風險 function；真實 app 需 input validation、authorisation、audit 與必要的 human approval。
- 不把 web search 結果或 model output 當權威事實；特別是 policy、價格與醫療 / 法律等高風險內容。
- 防護控制要隔離：M06 strict guardrail 不應破壞早先的 chat 或 tool demos。

### 9.6 課後收尾
- 再次指出 course material 在 Microsoft Learn，未在課堂講完的內容是預期設計，不是漏教。
- 提醒學員領取 Achievement Code，並在 Microsoft Learn profile 追蹤學習。
- 說明 AI-103 關係時用「部分對齊」而非「保證通過」。
- 提供 M07 standalone module 與兩個 lab index，讓有興趣的學員延伸。
- 課後確認 backup environment 不再需要時執行：
```powershell
cd TERRAFORM
terraform destroy -var group_postfix=0821
```
---

## 10. 參考

### 課程與 Learn
- [AI-3016 learning path — Develop generative AI apps in Azure](https://learn.microsoft.com/en-us/training/paths/develop-generative-ai-apps/)
- [M01 — Plan and prepare to develop AI solutions on Azure](https://learn.microsoft.com/en-us/training/modules/prepare-azure-ai-development/)
- [M02 — Select, deploy, and evaluate Microsoft Foundry Models](https://learn.microsoft.com/en-us/training/modules/model-catalog-evaluate/)
- [M03 — Develop a generative AI chat app with Microsoft Foundry](https://learn.microsoft.com/en-us/training/modules/foundry-sdk/)
- [M04 — Develop generative AI apps that use tools](https://learn.microsoft.com/en-us/training/modules/use-generative-ai-tools/)
- [M05 — Optimize generative AI model performance with Microsoft Foundry](https://learn.microsoft.com/en-us/training/modules/optimize-generative-ai-model-performance/)
- [M06 — Implement a responsible generative AI solution in Microsoft Foundry](https://learn.microsoft.com/en-us/training/modules/responsible-ai-studio/)
- [M07 — Develop AI agents with Microsoft Foundry and Visual Studio Code](https://learn.microsoft.com/en-us/training/modules/develop-ai-agents-azure-vs-code/)（standalone）

### Lab repositories
- [mslearn-ai-studio lab index（M01–M06）](https://microsoftlearning.github.io/mslearn-ai-studio/)
- [mslearn-ai-agents lab index（M07）](https://microsoftlearning.github.io/mslearn-ai-agents/)
- [M01 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/01-Explore-ai-studio.html)
- [M02 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/02-model-catalog-evaluation.html)
- [M03 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/03-foundry-sdk.html)
- [M04 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/04a-use-own-data.html)
- [M05 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/04b-finetune-model.html)
- [M06 exercise](https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/Exercises/06-Explore-content-filters.html)
- [M07 exercise](https://microsoftlearning.github.io/mslearn-ai-agents/Instructions/Exercises/01-build-agent-portal-and-vscode.html)

### 講師內部文件與產品參考
- [TERRAFORM backup environment README](../TERRAFORM/README.md)
- [Demo / backup environment 說明](demo-environment.md)
- [Foundry model retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)
- [Fine-tuning models support table](https://learn.microsoft.com/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure?pivots=azure-openai#fine-tuning-models)
- [AI-103 — Microsoft Certified: Azure AI Apps and Agents Developer Associate](https://learn.microsoft.com/en-us/credentials/certifications/azure-ai-apps-and-agents-developer-associate/)

### 本指南的第一手課程來源
- `PPT/AI-3016-ENU-PowerPoint_00-Introduction.pptx` 的抽取文字與講者備註。
- `PPT/AI-3016-ENU-PowerPoint-01.pptx` 的抽取文字與講者備註。
- `PPT/AI-3016-ENU-PowerPoint_02-Conclusion.pptx` 的抽取文字與講者備註。
- `PPT/AI-3016-ENU-TrainerPrepGuide.pdf`。
- `PPT/AI-3016-ENU-ChangeLog.pdf`（May 2026）。
