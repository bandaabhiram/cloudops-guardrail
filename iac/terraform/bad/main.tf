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
  name     = "rg-guardrail-bad"
  location = "uksouth"
}

# BAD: NSG allows SSH from anywhere (Internet)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-bad"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH-From-Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# BAD: Storage account intentionally misconfigured for scanners to catch
resource "azurerm_storage_account" "st" {
  name                            = "stguardrailbad12345"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"

  # Insecure settings (intentionally):
  https_traffic_only_enabled      = false
  min_tls_version                 = "TLS1_0"
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = true
}

# BAD: Container exposed (public access)
resource "azurerm_storage_container" "public_container" {
  name                  = "public"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "blob"
}
