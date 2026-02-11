resource "azurerm_resource_group" "example" {
  name     = "Infrastructure"
  location = "West Europe"
}
# resource group name is required
# loaction is required 
# name is required

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
# network_interface_ids are required
resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "gateway_pip" {
  name                = "gateway-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "gateway_nic" {
  name                = "gateway-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  enable_ip_forwarding = true 

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.4"
    public_ip_address_id          = azurerm_public_ip.gateway_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "Infrastructure-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B2ats_v2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.gateway_nic.id,
  ]
# size is requiered
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
# os disk is required
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server-gen1"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "infrastructure-nsg"
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
  network_interface_id      = azurerm_network_interface.gateway_nic.id
  network_security_group_id = azurerm_network_security_group.example.id
}

output "gateway_public_ip" {
  value = azurerm_public_ip.gateway_pip.ip_address
}