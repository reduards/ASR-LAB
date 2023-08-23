terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
  backend "local" {
    path = "asrdemo.tfstate"
  }
}

provider "azurerm" {
  features {}
}
