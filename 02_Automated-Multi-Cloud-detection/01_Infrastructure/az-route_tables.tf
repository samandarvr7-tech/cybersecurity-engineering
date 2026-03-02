resource "azurerm_route_table" "indiac-indiag" {
  name                = "indiac-indiag"
  location            = azurerm_resource_group.windows-client.location
  resource_group_name = azurerm_resource_group.windows-client.name

  route {
    name           = "windowsclient-gateway"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_route_table_association" "ad_assoc" {
  subnet_id      = azurerm_subnet.windows-client.id
  route_table_id = azurerm_route_table.indiac-indiag.id
}

resource "azurerm_route_table" "norway-india" {
  name                = "norway-india"
  location            = azurerm_resource_group.windows-ad.location
  resource_group_name = azurerm_resource_group.windows-ad.name

  route {
    name           = "ad-gateway"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_subnet_route_table_association" "client-assoc" {
  subnet_id      = azurerm_subnet.windows-ad.id
  route_table_id = azurerm_route_table.norway-india.id
}