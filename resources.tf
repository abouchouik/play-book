
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
  for_each = toset(concat(var.master_vms,var.worker_vms))
  name= "${each.value}nic"
  location= data.azurerm_resource_group.existant.location
  resource_group_name = data.azurerm_resource_group.existant.name

  ip_configuration {
    name= "myNICConfig"
    subnet_id= azurerm_subnet.existant.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Define the ssh key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Define the ssh privat key file
resource "local_file" "ssh_private_key" {
  content  = tls_private_key.key.private_key_pem
  filename = var.ansible_ssh_private_key_file
}

# Define the ssh ssh public key file
resource "local_file" "ssh_public_key" {
  content  = tls_private_key.key.public_key_pem
  filename = "${var.ansible_ssh_private_key_file}.pub"
}

# Define the virtual machine
resource "azurerm_linux_virtual_machine" "existant" {
  for_each = toset(concat(var.master_vms,var.worker_vms))
  name= each.value
  location= data.azurerm_resource_group.existant.location
  resource_group_name = data.azurerm_resource_group.existant.name

  size= "Standard_DS1_v2"
  admin_username= var.admin_name
  network_interface_ids = [azurerm_network_interface.existant[each.value].id]

  admin_ssh_key {
    username   = var.admin_name
    public_key = file("${var.ansible_ssh_private_key_file}.pub") 
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
resource "local_file" "ansible_inventory" {
   content  = templatefile("${path.module}/inventory.tftpl", {
    master_ip = azurerm_network_interface.existant[var.master_vms[0]],
    worker_ip = azurerm_network_interface.existant[var.worker_vms[0]],
    ansible_ssh_private_key_file = var.ansible_ssh_private_key_file
  })
  filename = "/home/azureuser/workspace/inventory.ini"
}