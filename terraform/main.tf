terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.72"
    }
  }

  cloud {
    organization = "YOUR_TFC_ORG"

    workspaces {
      name = "search-import-demo"
    }
  }
}

provider "azurerm" {
  features {}
}
