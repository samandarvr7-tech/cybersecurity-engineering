resource "azurerm_resource_group" "windows-client" {
  name     = "Multi-Cloud-Infrastructure-client"
  location = "Norway East"
}

resource "azurerm_virtual_network" "windows-client" {
  name                = "windows-client"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.windows-client.location
  resource_group_name = azurerm_resource_group.windows-client.name
}

resource "azurerm_subnet" "windows-client" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.windows-client.name
  virtual_network_name = azurerm_virtual_network.windows-client.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_interface" "windows-client" {
  name                = "windows-client-nic"
  location            = azurerm_resource_group.windows-client.location
  resource_group_name = azurerm_resource_group.windows-client.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.windows-client.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.4"
  }
}

resource "azurerm_windows_virtual_machine" "windows-client" {
  name                = "windows-client-machine"
  computer_name       = "win-client"
  resource_group_name = azurerm_resource_group.windows-client.name
  location            = azurerm_resource_group.windows-client.location
  size                = "Standard_B2ls_v2"
  admin_username      = "azureuser"
  admin_password      = var.windows_passwd
  network_interface_ids = [
    azurerm_network_interface.windows-client.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}