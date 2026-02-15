resource "azurerm_virtual_network_peering" "indiac-indiag" {
  name                      = "indiawindowsclient-indiagateway"
  resource_group_name       = azurerm_resource_group.windows-client.name
  virtual_network_name      = azurerm_virtual_network.windows-client.name
  remote_virtual_network_id = azurerm_virtual_network.example.id
  allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "indiag-indiac" {
  name                      = "indiagateway-indiawindowsclient"
  resource_group_name       = azurerm_resource_group.example.name
  virtual_network_name      = azurerm_virtual_network.example.name
  remote_virtual_network_id = azurerm_virtual_network.windows-client.id
  allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "norway-india" {
  name                      = "norway-india"
  resource_group_name       = azurerm_resource_group.windows-ad.name
  virtual_network_name      = azurerm_virtual_network.windows-ad.name
  remote_virtual_network_id = azurerm_virtual_network.example.id
  allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "india-norway" {
  name                      = "india-norway"
  resource_group_name       = azurerm_resource_group.example.name
  virtual_network_name      = azurerm_virtual_network.example.name
  remote_virtual_network_id = azurerm_virtual_network.windows-ad.id
  allow_forwarded_traffic = true
}