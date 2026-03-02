resource "azurerm_resource_group" "windows-ad" {
  name     = "Multi-Cloud-Infrastructure-ad"
  location = "Central India"
}

resource "azurerm_virtual_network" "windows-ad" {
  name                = "windows-ad"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.windows-ad.location
  resource_group_name = azurerm_resource_group.windows-ad.name
}

resource "azurerm_subnet" "windows-ad" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.windows-ad.name
  virtual_network_name = azurerm_virtual_network.windows-ad.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_network_interface" "windows-ad" {
  name                = "windows-ad-nic"
  location            = azurerm_resource_group.windows-ad.location
  resource_group_name = azurerm_resource_group.windows-ad.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.windows-ad.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.1.4"
  }
}

resource "azurerm_windows_virtual_machine" "windows-ad" {
  name                = "windows-ad-machine"
  computer_name       = "win-ad"
  resource_group_name = azurerm_resource_group.windows-ad.name
  location            = azurerm_resource_group.windows-ad.location
  size                = "Standard_B2ls_v2"
  admin_username      = "azureuser"
  admin_password      = var.windows_passwd
  network_interface_ids = [
    azurerm_network_interface.windows-ad.id,
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
