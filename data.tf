# Define the resource group
data "azurerm_resource_group" "existant" {
  name     = var.resource_group_name
}
