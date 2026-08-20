###############################################################################
# AI-3016 - Resources for the "Develop generative AI apps in Azure" demos.
#
# Everything here is driven by MAIN.tf (variables + locals). Model selection is
# validated against the Foundry model retirement schedule; see the locals block
# in MAIN.tf and docs/demo-environment.md for the evidence table.
###############################################################################

###############################################################################
# Storage - staging for the demo sample data (travel brochures for the module 4
# tools demo, and the module 7 agent files).
###############################################################################
resource "azurerm_storage_account" "default" {
  name                            = "${local.class_name}${var.group_postfix}st${local.random_str}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  # Company policy forbids access keys - enforce Entra ID (AAD) auth only.
  shared_access_key_enabled = false

  tags = local.default_tags
}

# Travel brochures used by the module 4 file_search / vector store demo.
# Containers use storage_account_id (management plane) so they can be created
# without storage data-plane keys (which policy forbids).
resource "azurerm_storage_container" "brochures" {
  name                  = "brochures"
  storage_account_id    = azurerm_storage_account.default.id
  container_access_type = "private"
}

# Files attached to the module 7 demo agent (IT_Policy.txt, system_performance.csv).
resource "azurerm_storage_container" "agent_files" {
  name                  = "agent-files"
  storage_account_id    = azurerm_storage_account.default.id
  container_access_type = "private"
}

# Fine-tuning training data (travel-finetune-hotel.jsonl) used by module 5.
resource "azurerm_storage_container" "finetune" {
  name                  = "finetune"
  storage_account_id    = azurerm_storage_account.default.id
  container_access_type = "private"
}

###############################################################################
# Role assignments for Entra ID (AAD) data-plane access.
# Because access keys are disabled everywhere, every principal that touches
# blob or AI Services data needs an explicit RBAC role.
###############################################################################

# The principal running Terraform (and the data-plane scripts) needs to
# read/write blobs via AAD.
resource "azurerm_role_assignment" "deployer_blob" {
  scope                = azurerm_storage_account.default.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.deployer_oid
}

###############################################################################
# Microsoft Foundry account + project.
# kind = AIServices with project management enabled gives one resource that
# hosts the Azure OpenAI model deployments AND the Foundry project/agent
# surface the course uses.
# https://learn.microsoft.com/azure/foundry/how-to/create-resource-terraform
###############################################################################
resource "azurerm_cognitive_account" "foundry" {
  name                  = "${local.group_name_lower}-foundry-${local.random_str}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "AIServices"
  sku_name              = "S0"
  custom_subdomain_name = "${local.group_name_lower}-foundry-${local.random_str}"

  # Company policy enforces Entra ID (AAD) auth only - keys are disabled.
  # AAD auth requires a custom subdomain (regional endpoints reject AAD tokens).
  local_auth_enabled = false

  # Required for the modern ("New Foundry") experience and projects, which is
  # what every lab in this course uses.
  project_management_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.default_tags
}

resource "azurerm_cognitive_account_project" "project" {
  name                 = "${local.group_name_lower}-project"
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.default_tags
}

# The principal running the data-plane scripts calls the AI Services / Azure
# OpenAI data plane (vector stores, files, agents, fine-tuning) via AAD.
resource "azurerm_role_assignment" "deployer_cs_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = local.deployer_oid
}

# Creating vector stores, uploading files, submitting fine-tuning jobs and
# creating agents are all write operations on the OpenAI data plane.
resource "azurerm_role_assignment" "deployer_openai_contributor" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = local.deployer_oid
}

# The Foundry account's managed identity reads the staged sample data.
resource "azurerm_role_assignment" "foundry_blob" {
  scope                = azurerm_storage_account.default.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_cognitive_account.foundry.identity[0].principal_id
}

###############################################################################
# Custom guardrail (module 6).
#
# The lab has students build a custom content filter and apply it to a
# deployment. This pre-builds an equivalent strict guardrail so the demo works
# immediately.
#
# It is deliberately attached to its OWN deployment (see gpt_guarded below) so
# the strict thresholds never interfere with the module 1/3/4 demos that share
# the main chat deployment.
#
# Blocking is probabilistic: demo the fact that the policy is attached and the
# categories it covers, rather than promising one exact blocked response.
###############################################################################
resource "azurerm_cognitive_account_rai_policy" "strict" {
  name                 = "${local.class_name}-strict-guardrail"
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  base_policy_name     = "Microsoft.DefaultV2"
  mode                 = "Blocking"

  # Prompt-side filters (what the user sends in).
  content_filter {
    name               = "Hate"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
    source             = "Prompt"
  }

  content_filter {
    name               = "Violence"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
    source             = "Prompt"
  }

  content_filter {
    name               = "Sexual"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
    source             = "Prompt"
  }

  content_filter {
    name               = "Selfharm"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
    source             = "Prompt"
  }

  # Completion-side filters (what the model sends back).
  content_filter {
    name               = "Hate"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
    source             = "Completion"
  }

  content_filter {
    name               = "Violence"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
    source             = "Completion"
  }

  content_filter {
    name               = "Sexual"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
    source             = "Completion"
  }

  content_filter {
    name               = "Selfharm"
    filter_enabled     = true
    block_enabled      = true
    severity_threshold = "Low"
    source             = "Completion"
  }

  tags = local.default_tags
}

###############################################################################
# Model deployments.
#
# Deployments are created one at a time (depends_on chain) because the
# Cognitive Services control plane rejects parallel deployment writes.
#
# Deployment names deliberately match the model names, because that is the
# default the labs produce ("deploy it using the default settings") and the
# trainer demo should mirror what students see.
###############################################################################

# Main chat model - modules 1, 3 and 4 (playground, Responses API, tools).
resource "azurerm_cognitive_deployment" "chat" {
  name                 = local.models.chat.name
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  sku {
    name     = "GlobalStandard"
    capacity = var.chat_capacity
  }

  model {
    format  = "OpenAI"
    name    = local.models.chat.name
    version = local.models.chat.version
  }
}

# Smaller model used for the module 2 leaderboard / side-by-side comparison.
resource "azurerm_cognitive_deployment" "compare" {
  name                 = local.models.compare.name
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  sku {
    name     = "GlobalStandard"
    capacity = var.compare_capacity
  }

  model {
    format  = "OpenAI"
    name    = local.models.compare.name
    version = local.models.compare.version
  }

  depends_on = [azurerm_cognitive_deployment.chat]
}

# Module 5 fine-tuning baseline. The fine-tuned model itself is created by
# scripts/Start-FineTune.ps1 BEFORE class (training takes 60+ minutes), and is
# deployed by the fine-tuning job onto the Developer tier.
resource "azurerm_cognitive_deployment" "finetune_base" {
  name                 = local.finetune_base.name
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  sku {
    name     = "GlobalStandard"
    capacity = var.finetune_base_capacity
  }

  model {
    format  = "OpenAI"
    name    = local.finetune_base.name
    version = local.finetune_base.version
  }

  depends_on = [azurerm_cognitive_deployment.compare]
}

# Module 6 - isolated deployment carrying the strict custom guardrail.
resource "azurerm_cognitive_deployment" "chat_guarded" {
  name                 = "${local.models.chat.name}-guarded"
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  rai_policy_name      = azurerm_cognitive_account_rai_policy.strict.name

  sku {
    name     = "GlobalStandard"
    capacity = var.guarded_capacity
  }

  model {
    format  = "OpenAI"
    name    = local.models.chat.name
    version = local.models.chat.version
  }

  depends_on = [azurerm_cognitive_deployment.finetune_base]
}

###############################################################################
# Data-plane automation.
#
# Brings the environment to a "completed" demo-ready state:
#   1. download the official course sample data and stage it in blob storage
#   2. create a vector store pre-loaded with the travel brochures (module 4)
#   3. create a demo agent with file_search + code_interpreter (module 7)
#
# Fine-tuning is NOT part of apply - it takes 60+ minutes and is triggered
# separately by scripts/Start-FineTune.ps1 before class.
#
# Each step runs a PowerShell 7 script that authenticates with `az` bearer
# tokens, so an authenticated `az login` session is required.
###############################################################################

locals {
  pwsh        = "pwsh"
  pwsh_args   = ["-NoProfile", "-File"]
  scripts_dir = "${path.module}/scripts"
  staging_dir = "${path.module}/.sample-data"

  vector_store_name = "ai3016-margies-travel"
  demo_agent_name   = "ai3016-demo-agent"

  # v1 Azure OpenAI endpoint used by the labs and the slide code samples.
  openai_v1_endpoint = "https://${azurerm_cognitive_account.foundry.custom_subdomain_name}.openai.azure.com/openai/v1"

  # Foundry project endpoint used by the Agent Service / azure-ai-projects SDK.
  project_endpoint = "https://${azurerm_cognitive_account.foundry.custom_subdomain_name}.services.ai.azure.com/api/projects/${azurerm_cognitive_account_project.project.name}"
}

resource "terraform_data" "sample_data" {
  count = var.enable_data_plane ? 1 : 0

  triggers_replace = [
    azurerm_storage_account.default.id,
    filesha256("${local.scripts_dir}/Get-SampleData.ps1"),
  ]

  depends_on = [
    azurerm_storage_container.brochures,
    azurerm_storage_container.agent_files,
    azurerm_storage_container.finetune,
    azurerm_role_assignment.deployer_blob,
  ]

  provisioner "local-exec" {
    interpreter = concat([local.pwsh], local.pwsh_args)
    command     = "${local.scripts_dir}/Get-SampleData.ps1"

    environment = {
      STORAGE_ACCOUNT       = azurerm_storage_account.default.name
      BROCHURES_CONTAINER   = azurerm_storage_container.brochures.name
      AGENT_FILES_CONTAINER = azurerm_storage_container.agent_files.name
      FINETUNE_CONTAINER    = azurerm_storage_container.finetune.name
      STAGING_PATH          = local.staging_dir
    }
  }
}

resource "terraform_data" "vector_store" {
  count = var.enable_data_plane ? 1 : 0

  triggers_replace = [
    azurerm_cognitive_account.foundry.id,
    filesha256("${local.scripts_dir}/New-DemoVectorStore.ps1"),
  ]

  depends_on = [
    terraform_data.sample_data,
    azurerm_cognitive_deployment.chat,
    azurerm_role_assignment.deployer_cs_user,
    azurerm_role_assignment.deployer_openai_contributor,
  ]

  provisioner "local-exec" {
    interpreter = concat([local.pwsh], local.pwsh_args)
    command     = "${local.scripts_dir}/New-DemoVectorStore.ps1"

    environment = {
      OPENAI_V1_ENDPOINT = local.openai_v1_endpoint
      VECTOR_STORE_NAME  = local.vector_store_name
      BROCHURES_PATH     = "${local.staging_dir}/brochures"
    }
  }
}

resource "terraform_data" "demo_agent" {
  count = var.enable_data_plane && var.enable_demo_agent ? 1 : 0

  triggers_replace = [
    azurerm_cognitive_account_project.project.id,
    filesha256("${local.scripts_dir}/New-DemoAgent.ps1"),
  ]

  depends_on = [
    terraform_data.vector_store,
    azurerm_role_assignment.deployer_cs_user,
    azurerm_role_assignment.deployer_openai_contributor,
  ]

  provisioner "local-exec" {
    interpreter = concat([local.pwsh], local.pwsh_args)
    command     = "${local.scripts_dir}/New-DemoAgent.ps1"

    environment = {
      PROJECT_ENDPOINT = local.project_endpoint
      AGENT_NAME       = local.demo_agent_name
      MODEL_DEPLOYMENT = azurerm_cognitive_deployment.chat.name
      AGENT_FILES_PATH = "${local.staging_dir}/agent-files"
    }
  }
}