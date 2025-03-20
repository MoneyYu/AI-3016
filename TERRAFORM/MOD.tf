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

# 這個資源用於建立 Azure Cognitive Services，提供 AI 與機器學習等功能
resource "azapi_resource" "AIServicesResource" {
  type      = "Microsoft.CognitiveServices/accounts@2023-10-01-preview"
  name      = "${local.group_name_lower}-ai-svc-res-${local.random_str}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    name = "${local.group_name_lower}-ai-svc-res-${local.random_str}"
    properties = {
      //restore = true
      customSubDomainName = "${local.group_name_lower}-${local.random_str}-domain"
      apiProperties = {
        statisticsEnabled = false
      }
    }
    kind = "AIServices"
    sku = {
      name = "S0"
    }
  }

  response_export_values = ["*"]

  tags = {
    environment = local.group_name
  }
}

// 這個資源用於建立 Azure Machine Learning 服務工作區，提供自動化機器學習等功能
resource "azapi_resource" "hub" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01-preview"
  name      = "${local.group_name_lower}-ai-hub-${local.random_str}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      description    = "${local.group_name} Azure AI hub"
      friendlyName   = "${local.group_name} Hub"
      storageAccount = azurerm_storage_account.default.id
      keyVault       = azurerm_key_vault.default.id

      /* Optional: To enable these field, the corresponding dependent resources need to be uncommented.
      applicationInsight = azurerm_application_insights.default.id
      containerRegistry = azurerm_container_registry.default.id
      */

      /*Optional: To enable Customer Managed Keys, the corresponding 
      encryption = {
        status = var.encryption_status
        keyVaultProperties = {
            keyVaultArmId = azurerm_key_vault.default.id
            keyIdentifier = var.cmk_keyvault_key_uri
        }
      }
      */

    }
    kind = "Hub"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azapi_resource" "project" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01-preview"
  name      = "${local.group_name_lower}-ai-project-${local.random_str}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      description   = "${local.group_name} Azure AI Project"
      friendlyName  = "${local.group_name} Project"
      hubResourceId = azapi_resource.hub.id
    }
    kind = "project"
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