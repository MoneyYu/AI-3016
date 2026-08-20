###############################################################################
# AI-3016 - Outputs
#
# Endpoints and names only - never secrets. Every data plane in this stack uses
# Entra ID (AAD), so there are no keys to emit.
###############################################################################

output "resource_group_name" {
  description = "Resource group holding the backup demo environment."
  value       = azurerm_resource_group.rg.name
}

output "demo_resource_group_name" {
  description = "Empty resource group for the live from-scratch demo built during class."
  value       = azurerm_resource_group.demo_rg.name
}

output "location" {
  description = "Region the demo environment is deployed to."
  value       = local.location
}

output "foundry_account_name" {
  description = "Microsoft Foundry (AIServices) account name."
  value       = azurerm_cognitive_account.foundry.name
}

output "foundry_project_name" {
  description = "Microsoft Foundry project name."
  value       = azurerm_cognitive_account_project.project.name
}

output "foundry_endpoint" {
  description = "AI Services endpoint of the Foundry account."
  value       = azurerm_cognitive_account.foundry.endpoint
}

output "azure_openai_v1_endpoint" {
  description = "Azure OpenAI v1 endpoint. This is the AZURE_OPENAI_ENDPOINT value the labs and the slide code samples use with the OpenAI SDK."
  value       = local.openai_v1_endpoint
}

output "model_profile" {
  description = "Which model profile was deployed (parity = what the labs tell students to deploy; current = newer GA replacements)."
  value       = var.model_profile
}

output "model_deployment" {
  description = "Main chat deployment name. Set this as the MODEL_DEPLOYMENT environment variable for the demo code so the slide samples are not hard-coded to gpt-4.1."
  value       = azurerm_cognitive_deployment.chat.name
}

output "compare_deployment" {
  description = "Second, smaller chat deployment used for the module 2 side-by-side comparison."
  value       = azurerm_cognitive_deployment.compare.name
}

output "finetune_base_deployment" {
  description = "Base deployment used as the module 5 fine-tuning baseline. The fine-tuned model is created separately by scripts/Start-FineTune.ps1."
  value       = azurerm_cognitive_deployment.finetune_base.name
}

output "guarded_deployment" {
  description = "Isolated deployment carrying the strict custom guardrail for the module 6 demo."
  value       = azurerm_cognitive_deployment.chat_guarded.name
}

output "guardrail_policy_name" {
  description = "Name of the pre-built custom guardrail (RAI policy)."
  value       = azurerm_cognitive_account_rai_policy.strict.name
}

output "storage_account_name" {
  description = "Storage account staging the course sample data."
  value       = azurerm_storage_account.default.name
}

output "foundry_portal_url" {
  description = "Direct link to the Foundry portal for this subscription."
  value       = "https://ai.azure.com"
}

output "demo_env_file" {
  description = "Ready-to-paste .env contents for the demo client applications."
  value       = <<-EOT
    AZURE_OPENAI_ENDPOINT=${local.openai_v1_endpoint}
    MODEL_DEPLOYMENT=${azurerm_cognitive_deployment.chat.name}
    COMPARE_DEPLOYMENT=${azurerm_cognitive_deployment.compare.name}
    GUARDED_DEPLOYMENT=${azurerm_cognitive_deployment.chat_guarded.name}
    FINETUNE_BASE_DEPLOYMENT=${azurerm_cognitive_deployment.finetune_base.name}
  EOT
}