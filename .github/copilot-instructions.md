# AI-3016 — Copilot instructions

Trainer reference repo for the Microsoft instructor-led course **AI-3016: Develop generative AI
apps in Azure**. It is not an application: there is no build and no test suite. The deliverables
are an attendee-facing `README.md`, a trainer-only `docs/` folder, and a Terraform "backup demo
environment".

## Repository layout

| Path | Audience | Contents |
|---|---|---|
| `README.md` | **Attendees** | HackMD-style course reference page (English) |
| `docs/` | **Trainer only** | `demo-environment.md`, `teaching-guide.md` (Traditional Chinese) |
| `TERRAFORM/` | **Trainer only** | Backup demo stack (`MAIN.tf` / `MOD.tf` / `OUTPUT.tf` + `scripts/`) |
| `PPT/` | Trainer only | Official decks, Trainer Prep Guide, Change Log |
| `archive/` | — | Superseded pre-May-2025 material (Prompt Flow). Do not resurrect. |

**Never put demo-environment details, model-choice rationale, Terraform, or Skillable internals
in `README.md`.** Those belong in `docs/`.

## Language conventions

- `README.md`: **English**.
- `docs/`, `TERRAFORM/README.md`, and code comments: **正體中文 (Traditional Chinese)**, with
  technical terms, product names, API names, model names and URLs kept in English.
- Never use Simplified Chinese.

## README conventions (HackMD, not plain GitHub Markdown)

- Preserve the YAML front-matter (`image`, `tags`, Google Analytics `GA`).
- Preserve admonitions: `:::success`, `:::info`, `:::warning` … `:::`.
- Standalone reference links: **no blank line after a heading**, exactly **one** blank line
  between links, and **never** use bullet or numbered lists for them.
- Section order: `Course` → `Course Materials` → `Infos` → `Lab` → `Links` → `Videos` →
  `Mind Map` → `Contact`.
- `## Links` is grouped by **course module** (`### Mxx - <module name>`), never by service or by
  an invented taxonomy.
- The `## Mind Map` is a single ```` ```markmap ```` fenced block.
- **Per-instance metadata** (`Date`, `Course ID`, Course Survey, Skillable Training key) changes
  every delivery — do not touch it unless explicitly asked.

## Course facts that drive everything

- The course has **7 classroom lessons**: 6 from the Microsoft Learn learning path
  `develop-generative-ai-apps`, plus 1 **standalone** module
  (`develop-ai-agents-azure-vs-code`) whose lab lives in a **second** repo.
- Labs M01–M06: `MicrosoftLearning/mslearn-ai-studio`. Lab M07: `MicrosoftLearning/mslearn-ai-agents`.
  There is **no** `mslearn-ai-studio.zh-cn` repo any more (404) — labs are English-only.
- The course grants an **Achievement Code only**; the Applied Skills assessment retired 2026-04-15.
- Prompt Flow was **removed** from the course in May 2025. Branding is **Microsoft Foundry** and
  **Foundry Tools** (formerly Azure AI Foundry / Azure AI Studio and Azure AI Services).

## Model rules (time-sensitive — re-verify before every delivery)

1. **Always validate against the retirement schedule with today's date**:
   <https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule>
2. **Deprecated ≠ usable.** A subscription that has never deployed that exact model version
   **cannot** create a deployment. "Existing customer" is judged **per subscription**, so a
   Skillable lab subscription may fail where the trainer's subscription succeeds. Exclude
   deprecated models by default.
3. **Lab parity beats "latest GA"** for the primary profile: the trainer demo must mirror what
   students see. `var.model_profile` switches between `parity` (`gpt-5.2` + `gpt-5-mini`) and
   `current` (`gpt-5.4` + `gpt-5.4-mini`).
4. **Fine-tuning is a special case.** The lab asks for supervised fine-tuning on `gpt-5`, but the
   official table lists **RFT only** for `gpt-5` and that is gated/invitation-only. No gpt-5.x
   model supports SFT. Use **`gpt-4.1-mini`** — the only SFT-capable, non-deprecated model in a
   Sweden Central standard fine-tuning region that supports the Developer deployment type.
   The whole gpt-4.1 family retires 2027-04-14.
5. **Never trust web search for model capability claims** — confirm on learn.microsoft.com.
6. Quota key names are not model names: gpt-4.1 models appear as **`gpt4.1`** (no first dot),
   e.g. `OpenAI.GlobalStandard.gpt4.1-mini`.

## Terraform conventions

- File split is fixed: `MAIN.tf` = providers + variables + locals + resource groups;
  `MOD.tf` = all resources + data-plane wiring; `OUTPUT.tf` = endpoints and names, never secrets.
  **New resources go in `MOD.tf`.**
- All names derive from a single `var.group_postfix`, validated `^[a-z0-9]{1,10}$` because the
  storage account name uses it directly.
- `local.random_str` is a fixed suffix for stable names. Switching it to `random_string.rid.result`
  is a one-line change, used to dodge the ~48h Cognitive account soft-delete name reservation.
- Region is `local.location = "swedencentral"`, chosen deliberately (see `docs/demo-environment.md`).
  Do not change it casually.
- Foundry pattern: `azurerm_cognitive_account` kind `AIServices` with `project_management_enabled`
  and a `custom_subdomain_name`, then `azurerm_cognitive_account_project`, then one
  `azurerm_cognitive_deployment` per model.
- **Serialize every `Microsoft.CognitiveServices/accounts/*` child write with `depends_on`** —
  Azure allows only one control-plane operation at a time per account. This covers the project,
  the RAI policy and *all* model deployments, not just deployments. `azurerm` 4.81.0 locks
  deployments and RAI policies by account but **not** `azurerm_cognitive_account_project`
  (upstream fix: hashicorp/terraform-provider-azurerm#33151), so the chain must be explicit.
  Keep it after upgrading: provider mutexes are process-local and cannot coordinate with
  `Start-FineTune.ps1`, the portal, or another pipeline. `Microsoft.Authorization` role
  assignments are a different resource provider and stay parallel.
- **Put the fine-tune cleanup marker at the END of that chain** so `destroy` (which reverses it)
  removes untracked fine-tuned deployments before any managed child resource is deleted.
- Apply `tags = local.default_tags` to every taggable resource.
- **Entra ID (AAD) only.** Storage `shared_access_key_enabled = false`, provider
  `storage_use_azuread = true`, Cognitive `local_auth_enabled = false` (which *requires*
  `custom_subdomain_name`). Create the RBAC role assignments the data plane needs and make
  data-plane resources `depends_on` them.
- The strict module 6 guardrail must stay on **its own deployment** so it never affects the
  other demos.

## Data-plane script conventions

- PowerShell 7 (`pwsh -NoProfile -File`) plus Azure CLI; AAD bearer tokens from
  `az account get-access-token` (try `https://ai.azure.com` first, fall back to
  `https://cognitiveservices.azure.com`).
- Every script starts with `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`,
  and uses a `Get-RequiredEnv` helper. **Env-var names in each `environment` map in `MOD.tf` must
  exactly match that script's `Get-RequiredEnv` calls** — this is the most common silent breakage.
- **Retry on 401/403** to absorb RBAC propagation. `az` permission errors do not always contain
  "401"/"403" (they can just say "You do not have the required permissions"), so match broadly.
- Polling loops must **throw on terminal failure and on timeout** — never silently exit 0.
- The Azure OpenAI REST response has **no `output_text` field** (that is an SDK convenience);
  read the `output` array.
- Sample data is **downloaded from the official lab repos at apply time**, never committed.

## Validation commands

```powershell
# Terraform (run from TERRAFORM/)
terraform fmt -recursive
terraform init -backend=false
terraform validate

# PowerShell scripts - AST parse (there is no test runner)
Get-ChildItem TERRAFORM/scripts/*.ps1 | ForEach-Object {
  $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$null,[ref]$e)
  if ($e.Count) { "FAIL: $($_.Name)"; $e } else { "OK: $($_.Name)" }
}

# Model availability preflight - REQUIRED before any real apply
./TERRAFORM/scripts/Test-ModelAvailability.ps1

# Link checking (uses the repo venv)
./.venv/Scripts/python.exe .github/skills/course-prep/scripts/link_check.py urls.txt
```

A real `terraform apply` needs `az login`, a target subscription and model quota, so it cannot run
in CI. Use the date as `group_postfix` (e.g. `0821`) and always `destroy` afterwards.

## The backup environment is NOT an emergency switch

Fine-tuning takes 60+ minutes and several data-plane steps are asynchronous. The stack is meant to
be applied **1–2 days before class**, smoke-tested, kept running during delivery, and destroyed
afterwards. Any doc you write must say this.

## Binary assets

The global `* text=auto` in `.gitattributes` will corrupt PDFs/PPTX/PNGs. New binary types must be
marked `binary` in `.gitattributes` **before** committing.

## Git

- Conventional Commits: `<type>(<scope>): <description>`, grouped logically (README / Terraform /
  docs / chore) rather than one mega-commit.
- Append the trailer `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`.
- Tracking issues: the **body holds the scope**; **progress goes in comments**, never edited back
  into the body.