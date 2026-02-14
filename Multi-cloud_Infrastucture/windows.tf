variable "windows_ad_passwd" {
  description = "AD server password"
  type        = string
}

resource "azurerm_network_interface" "windows-ad" {
  name                = "windows-ad-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.5"
  }
}

resource "azurerm_windows_virtual_machine" "windows-ad" {
  name                = "windows-ad-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B2ls_v2"
  admin_username      = "azureuser"
  admin_password      = var.windows_ad_passwd
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