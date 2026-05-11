terraform {
  required_version = ">= 1.14.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.72"
    }
  }

  cloud {
    # This is the demo author's HCP Terraform organization.
    # Change this to your own organization before running the demo elsewhere.
    organization = "lab-larry"

    workspaces {
      name = "search-import-demo"
    }
  }
}

provider "azurerm" {
  features {}
}
