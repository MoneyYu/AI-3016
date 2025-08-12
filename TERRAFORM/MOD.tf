# 這個 Storage Account 資源用於儲存檔案、Blob 等資料
resource "azurerm_storage_account" "default" {
  name                            = "${local.class_name}${var.group_postfix}stor${local.random_str}"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  tags = {
    environment = local.group_name
  }
}

# 這個 Key Vault 資源用於安全地儲存並管理機密資訊
resource "azurerm_key_vault" "default" {
  name                     = "${local.group_name_lower}-key-${local.random_str}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false

  tags = {
    environment = local.group_name
  }
}

# Deploy Azure AI Services resource
resource "azurerm_ai_services" "AIServicesResource" {
  name                = "${local.group_name_lower}-ai-svc-res-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "S0" # Pricing SKU tier

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_ai_foundry" "hub" {
  name                = "${local.group_name_lower}-ai-hub-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  storageAccount      = azurerm_storage_account.default.id
  keyVault            = azurerm_key_vault.default.id

  identity {
    type = "SystemAssigned" # Enable system-assigned managed identity
  }

  tags = {
    environment = local.group_name
  }
}

# Create an AI Foundry Project within the AI Foundry service
resource "azurerm_ai_foundry_project" "project" {
  name               = "${local.group_name_lower}-ai-project-${local.random_str}"
  location           = azurerm_ai_foundry.rg.location # Location from the AI Foundry service
  ai_services_hub_id = azurerm_ai_foundry.hub.id      # Associated AI Foundry service

  identity {
    type = "SystemAssigned" # Enable system-assigned managed identity
  }

  tags = {
    environment = local.group_name
  }
}

resource "azapi_resource" "AIServicesConnection" {
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01-preview"
  name      = "${local.group_name_lower}-ai-svc-conn-${local.random_str}"
  parent_id = azapi_resource.hub.id

  body = {
    properties = {
      category      = "AIServices",
      target        = azapi_resource.AIServicesResource.output.properties.endpoint,
      authType      = "AAD",
      isSharedToAll = true,
      metadata = {
        ApiType    = "Azure",
        ResourceId = azapi_resource.AIServicesResource.id
      }
    }
  }

  response_export_values = ["*"]
}

resource "azurerm_cognitive_account" "default" {
  name                = "${local.group_name_lower}-ai-svc-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "S0"
  kind                = "CognitiveServices"

  tags = {
    environment = local.group_name
  }
}
