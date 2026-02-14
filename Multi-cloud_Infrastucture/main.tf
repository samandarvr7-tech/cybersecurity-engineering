terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"           
    storage_account_name = "tfstatedtpdso718" 
    container_name       = "tfstate"              
    key                  = "terraform.tfstate"    
  }
}

provider "azurerm" {
  features {}
}

variable "ssh_public_key" {
  description = "The Public Key for the VM"
  type        = string
}

variable "windows_passwd" {
  description = "windows vm passwords"
  type        = string
}

resource "azurerm_resource_group" "example" {
  name     = "Multi-Cloud-Infrastructure"
  location = "Central India"
}

resource "azurerm_virtual_network" "example" {
  name                = "gateway"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "gateway-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "example" {
  name                = "gateway-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_forwarding_enabled = true 

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "Gateway"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B2ats_v2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server-gen1"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "gateway-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"  
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowInternalLab"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"              
    source_port_range          = "*"
    destination_port_range     = "*"
    
    source_address_prefix      = "VirtualNetwork" 
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

output "gateway_public_ip" {
  value = azurerm_public_ip.example.ip_address
}