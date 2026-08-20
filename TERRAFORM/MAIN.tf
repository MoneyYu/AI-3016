###############################################################################
# AI-3016 - Develop generative AI apps in Azure
# Backup / fallback demo environment (deployed, demo-ready end state).
#
# IMPORTANT - how this stack is meant to be used:
#   This is NOT an "apply it when the live demo fails" emergency switch.
#   Fine-tuning takes 60+ minutes and several data-plane steps are asynchronous,
#   so deploy this 1-2 DAYS BEFORE the class, smoke-test it, keep it running
#   during delivery, and destroy it afterwards. See TERRAFORM/README.md.
#
# Providers and core scaffolding live here; all resources live in MOD.tf and
# outputs in OUTPUT.tf.
###############################################################################

terraform {
  required_version = ">=1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 4.x is required for the modern Foundry surface:
      # azurerm_cognitive_account.project_management_enabled,
      # azurerm_cognitive_account_project and azurerm_cognitive_account_rai_policy.
      version = "~>4.20"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6"
    }
  }
}

provider "azurerm" {
  # Company policy forbids storage account access keys - use Entra ID (AAD)
  # for all storage data-plane operations.
  storage_use_azuread = true

  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

###############################################################################
# Variables
###############################################################################

variable "group_postfix" {
  description = "Unique suffix for the class/instance (keeps resource names unique). Lowercase letters and digits only, max 10 chars (the storage account name uses it directly)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.group_postfix))
    error_message = "group_postfix must be 1-10 lowercase letters/digits only (no hyphens, underscores, or uppercase) so the storage account name stays valid (<=24 chars, lowercase alphanumeric)."
  }
}

variable "model_profile" {
  description = <<-EOT
    Which set of chat models to deploy.

      parity  - exactly what the lab instructions tell students to deploy
                (gpt-5.2 + gpt-5-mini). Default: the trainer demo should mirror
                what students see on screen.
      current - newer GA replacements (gpt-5.4 + gpt-5.4-mini). Switch to this
                if the parity models stop being deployable (gpt-5 / gpt-5-mini
                passed the 12-month "new customers can't deploy" boundary of
                their 18-month lifecycle on 2026-08-07).

    Run scripts/Test-ModelAvailability.ps1 before apply to decide.
  EOT
  type        = string
  default     = "parity"

  validation {
    condition     = contains(["parity", "current"], var.model_profile)
    error_message = "model_profile must be either \"parity\" or \"current\"."
  }
}

# Model capacities, in thousands of tokens-per-minute. Checked against the
# swedencentral quota of the target subscription on 2026-08-20:
#   gpt-5.2       1280/3000 used   gpt-5-mini    1150/3000 used
#   gpt-5.4       1125/3000 used   gpt-5.4-mini  3595/6000 used
#   gpt4.1-mini   8000/15000 used  gpt4.1        3075/3075 used (EXHAUSTED)
variable "chat_capacity" {
  description = "Capacity for the main chat deployment (modules 1, 3, 4)."
  type        = number
  default     = 50
}

variable "compare_capacity" {
  description = "Capacity for the second, smaller chat deployment used for the module 2 side-by-side comparison."
  type        = number
  default     = 30
}

variable "finetune_base_capacity" {
  description = "Capacity for the gpt-4.1-mini base deployment used as the module 5 fine-tuning baseline."
  type        = number
  default     = 30
}

variable "guarded_capacity" {
  description = "Capacity for the isolated deployment that carries the strict custom guardrail (module 6). Kept separate so the strict filter never affects the other demos."
  type        = number
  default     = 20
}

variable "deployer_object_id" {
  description = "Entra object ID that the data-plane scripts authenticate as (the `az login` identity). Defaults to the identity Terraform runs as. Override when Terraform runs under a different principal (e.g. a service principal) than `az`."
  type        = string
  default     = null
}

variable "enable_data_plane" {
  description = "Run the PowerShell data-plane scripts after the resources are created (sample data upload, vector store, demo agent)."
  type        = bool
  default     = true
}

variable "enable_demo_agent" {
  description = "Create the pre-built module 7 demo agent (file_search + code_interpreter). Requires enable_data_plane."
  type        = bool
  default     = true
}

###############################################################################
# Locals
###############################################################################

locals {
  group_name       = "AI3016-${var.group_postfix}"
  class_name       = "ai3016"
  group_name_lower = lower(local.group_name)

  # Region decision (2026-08-20). swedencentral is the only region that is
  # simultaneously:
  #   * in the region list the fine-tuning lab (04b) allows,
  #   * a Foundry Agents region with the full tool matrix (File Search,
  #     Code Interpreter, Function, Web Search - northcentralus has no
  #     Function tool support),
  #   * a standard fine-tuning region for the gpt-4.1 family, and
  #   * a Global Standard region for every model this course uses.
  # See docs/demo-environment.md for the full comparison table.
  location = "swedencentral"

  # Suffix used in resource names. Fixed by default for predictable, stable
  # names. To use a fresh dynamic suffix instead (e.g. to avoid the ~48h
  # soft-delete name reservation on Cognitive accounts after a destroy/
  # recreate), change this one line to: random_str = random_string.rid.result
  random_str = "gen"

  # Entra object ID that the data-plane scripts authenticate as (the `az`
  # identity). Defaults to the identity Terraform runs as.
  deployer_oid = coalesce(var.deployer_object_id, data.azurerm_client_config.current.object_id)

  # Shared tags applied to every taggable resource. SecurityControl = "Ignore"
  # exempts these lab/demo resources from security/CSPM policy.
  default_tags = {
    environment     = local.group_name
    SecurityControl = "Ignore"
  }

  # ---------------------------------------------------------------------------
  # Model selection. Validated against the Foundry model retirement schedule
  # (https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule)
  # on 2026-08-20. Re-check before every delivery - see Phase 4 of the
  # course-prep skill and docs/demo-environment.md.
  # ---------------------------------------------------------------------------
  model_profiles = {
    # What the labs actually tell students to deploy.
    parity = {
      chat    = { name = "gpt-5.2", version = "2025-12-11" }    # GA, retires 2027-06-08
      compare = { name = "gpt-5-mini", version = "2025-08-07" } # GA, retires 2027-02-09
    }
    # Newer GA replacements with a longer runway.
    current = {
      chat    = { name = "gpt-5.4", version = "2026-03-05" }      # GA, retires 2027-09-02
      compare = { name = "gpt-5.4-mini", version = "2026-03-17" } # GA, retires 2027-09-21
    }
  }

  models = local.model_profiles[var.model_profile]

  # Fine-tuning baseline for module 5.
  #
  # The lab tells students to run SUPERVISED fine-tuning on gpt-5, but the
  # official supported-models table lists RFT only for gpt-5, and gpt-5 RFT is
  # gated (invitation only). gpt-4.1-mini is the only model that is
  # simultaneously SFT-capable, NOT deprecated, offered in the swedencentral
  # standard fine-tuning region, and supports the Developer deployment type.
  #
  # gpt-4.1 (full) was rejected: the target subscription has 3075/3075 Global
  # Standard quota used in swedencentral, i.e. none free.
  #
  # NOTE: the entire SFT surface (the gpt-4.1 family) is Legacy and retires
  # 2027-04-14. Re-validate before every delivery.
  finetune_base = { name = "gpt-4.1-mini", version = "2025-04-14" }
}

data "azurerm_client_config" "current" {}

# Dynamic random suffix. Kept available so you can switch resource naming from
# the fixed local.random_str to this (random_string.rid.result) when needed.
resource "random_string" "rid" {
  length  = 3
  special = false
  numeric = false
  upper   = false
}

###############################################################################
# Resource groups
###############################################################################

# Main resource group that holds the demo-ready backup environment.
resource "azurerm_resource_group" "rg" {
  name     = local.group_name
  location = local.location

  tags = local.default_tags
}

# Empty "Demo" resource group used when the trainer builds everything live
# from scratch during class.
resource "azurerm_resource_group" "demo_rg" {
  name     = "Demo${var.group_postfix}"
  location = local.location

  tags = local.default_tags
}
