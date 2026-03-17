terraform {
  backend "azurerm" {
    resource_group_name  = "rg-infra-docker-basics"
    storage_account_name = "sterraformstate19156"
    container_name       = "tfstate"
    key                  = "infra-docker-basics.tfstate"
  }
}
