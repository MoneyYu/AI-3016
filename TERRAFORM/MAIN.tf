terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azurerm" {
  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    key_vault {
      recover_soft_deleted_key_vaults    = false
      purge_soft_delete_on_destroy       = false
      purge_soft_deleted_keys_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

variable "group_postfix" {
  type = string
}

variable "user_name" {
  type    = string
  default = "demouser"
}

variable "user_passowrd" {
  type    = string
  default = "Azuredemo2020"
}

locals {
  group_name       = "AI3016-${var.group_postfix}"
  class_name       = "ai3016"
  group_name_lower = lower(local.group_name)
  location         = "eastus2"
  random_str       = "dog"
  admin_oid        = "b8e50bc5-6559-4643-a003-2807a8d707f7"
  lab01_name       = "lab01"
  lab02_name       = "lab02"
  lab03_name       = "lab03"
  lab04_name       = "lab04"
  lab05_name       = "lab05"
  lab06_name       = "lab06"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_client_config" "current" {}

resource "random_string" "rid" {
  length  = 3
  special = false
  numeric = false
  upper   = false
}

# resource "random_integer" "rint" {
#   min = 100
#   max = 999
# }

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "rg" {
  name     = local.group_name
  location = local.location

  tags = {
    environment = local.group_name
  }
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "demo-rg" {
  name     = "Demo${var.group_postfix}"
  location = local.location

  tags = {
    environment = local.group_name
  }
}

# resource "azurerm_resource_group" "demo" {
#   name     = "Demo${var.group_postfix}"
#   location = local.location

#   tags = {
#     environment = local.group_name
#   }
# }
