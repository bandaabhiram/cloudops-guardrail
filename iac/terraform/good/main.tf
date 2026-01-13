terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  use_cli                   = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-guardrail-good"
  location = "uksouth"
}

# GOOD: NSG restricts SSH to a known admin IP range (placeholder CIDR)
variable "admin_source_cidr" {
  description = "Trusted admin IP range for SSH (example: your public IP /32)"
  type        = string
  default     = "203.0.113.10/32"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-good"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-Trusted-Only"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }
}

# GOOD: Hardened storage account settings
resource "azurerm_storage_account" "st" {
  name                            = "stguardrailgood1234"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "GZRS"

  # Security hardening
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  # Passes CKV_AZURE_33 (queue logging enabled)
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 7
    }
  }

  # Default network access rule set to deny
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "private_container" {
  name                  = "private"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}
