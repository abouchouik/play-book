terraform {
  required_providers {
    azurerm = {

}
  }
  required_version = ">= 0.11"
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# Define the resource group
data "azurerm_resource_group" "existant" {
  name     = "Regroup_1aVpQg2QCG6AT"
}

variable "vms" {
    type = list(string)
    default = ["master", "worker"]
}

# Define the virtual network
resource "azurerm_virtual_network" "existant" {
  name= "myVNet"
  address_space= ["10.0.0.0/16"]
  location= data.azurerm_resource_group.existant.location
  resource_group_name = data.azurerm_resource_group.existant.name
}

# Define the subnet
resource "azurerm_subnet" "existant" {
  name= "mySubnet"
  resource_group_name  = data.azurerm_resource_group.existant.name
  virtual_network_name = azurerm_virtual_network.existant.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define the network interfaces

resource "azurerm_network_interface" "existant" {
  for_each = toset(var.vms)
  name= "${each.value}nic"
  location= data.azurerm_resource_group.existant.location
  resource_group_name = data.azurerm_resource_group.existant.name

  ip_configuration {
    name= "myNICConfig"
    subnet_id= azurerm_subnet.existant.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Define the ssh key
# resource "tls_private_key" "key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# # Define the ssh privat key file
# resource "local_file" "foo" {
#   content  = tls_private_key.key.private_key_pem
#   filename = "~/.ssh/id_rsa"
# }

# # Define the ssh ssh public key file
# resource "local_file" "foo" {
#   content  = tls_private_key.key.public_key_pem
#   filename = "~/.ssh/id_rsa.pub"
# }

# Define the virtual machine
resource "azurerm_linux_virtual_machine" "existant" {
  for_each = toset(var.vms)
  name= each.value
  location= data.azurerm_resource_group.existant.location
  resource_group_name = data.azurerm_resource_group.existant.name

  size= "Standard_DS1_v2"
  admin_username= "azureuser"
  network_interface_ids = [azurerm_network_interface.existant[each.value].id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/home/azureuser/workspace/ssh_key.pub") # Replace with the path to your public key
  }

  os_disk {
    caching= "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Generate inventory file
resource "local_file" "foo" {
  for_each = toset(var.vms)
  content  = templatefile("${path.module}/template.tftpl", {
    master_ip = azurerm_network_interface.existant[var.vms[0]] , worker_ip = azurerm_network_interface.existant[var.vms[1]] 
  })
  filename = "/home/azureuser/workspace/kuberentes-playbook/inventory.txt"
}