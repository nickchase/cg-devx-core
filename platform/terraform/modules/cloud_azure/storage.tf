resource "random_string" "sa_random_suffix" {
  length  = 8
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_storage_account" "storage_account" {
  name                = lower("${replace(replace(local.name, "_", ""), "-", "")}${random_string.sa_random_suffix.result}")
  resource_group_name = azurerm_resource_group.rg.name

  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = merge(local.tags, {
    "cg-devx.metadata.service" : "secret-manager"
  })
  public_network_access_enabled = true
  min_tls_version               = "TLS1_2"

  network_rules {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.private_subnet.id]
    ip_rules                   = [chomp(data.http.runner_ip_address.response_body)]
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags,
      network_rules.0.ip_rules
    ]
  }
}

resource "random_string" "sc_random_suffix" {
  length  = 8
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_storage_container" "artifacts_repository" {
  name                  = "${local.name}-artifacts-repository-${random_string.sc_random_suffix.id}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "backups_repository" {
  name                  = "${local.name}-backups-repository-${random_string.sc_random_suffix.id}"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}
