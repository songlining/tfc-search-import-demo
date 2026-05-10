variable "rg_name" {
  description = "Existing ClickOps resource group to use for scoped Search & Import queries."
  type        = string
}

list "azurerm_resource_group" "clickops" {
  provider         = azurerm
  include_resource = true

  config {
    filter = "tagName eq 'demo' and tagValue eq 'search-import-demo'"
  }
}

list "azurerm_storage_account" "clickops" {
  provider         = azurerm
  include_resource = true

  config {
    resource_group_name = var.rg_name
  }
}

list "azurerm_virtual_network" "clickops" {
  provider         = azurerm
  include_resource = true

  config {
    resource_group_name = var.rg_name
  }
}