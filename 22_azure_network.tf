# Create the required resources in Azure

resource "azurerm_virtual_network" "azure" {
  name                = var.azure_vnet_name
  location            = azurerm_resource_group.azure.location
  resource_group_name = azurerm_resource_group.azure.name
  address_space       = ["192.168.0.0/16"]
  dns_servers         = ["192.168.1.10"]
}

resource "azurerm_subnet" "azure-workload" {
  name                 = var.azure_subnet_name
  resource_group_name  = azurerm_resource_group.azure.name
  virtual_network_name = azurerm_virtual_network.azure.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_subnet" "azure-bastion" {
  count = var.use_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.azure.name
  virtual_network_name = azurerm_virtual_network.azure.name
  address_prefixes     = ["192.168.10.0/24"]
}

resource "azurerm_virtual_network" "azure-test" {
  name                = var.azure_test_vnet_name
  location            = azurerm_resource_group.azure.location
  resource_group_name = azurerm_resource_group.azure.name
  address_space       = ["192.168.0.0/16"]
  dns_servers         = ["192.168.1.10"]
}

resource "azurerm_subnet" "azure-test-workload" {
  name                 = var.azure_subnet_name
  resource_group_name  = azurerm_resource_group.azure.name
  virtual_network_name = azurerm_virtual_network.azure-test.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_subnet" "azure-test-bastion" {
  count = var.use_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.azure.name
  virtual_network_name = azurerm_virtual_network.azure-test.name
  address_prefixes     = ["192.168.10.0/24"]
}

resource "azurerm_network_security_group" "azure" {
  name                = var.azure_nsg_name
  location            = azurerm_resource_group.azure.location
  resource_group_name = azurerm_resource_group.azure.name
}

resource "azurerm_network_security_rule" "azure-public" {
  count                       = var.use_public_ip_address ? 1 : 0
  name                        = "AllowAdmin"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22","3389"]
  source_address_prefix       = var.admin_ip_address
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.azure.name
  network_security_group_name = azurerm_network_security_group.azure.name
}

resource "azurerm_subnet_network_security_group_association" "azure-nsg-workload-subnet" {
  subnet_id                 = azurerm_subnet.azure-workload.id
  network_security_group_id = azurerm_network_security_group.azure.id
}

resource "azurerm_subnet_network_security_group_association" "azure-nsg-test-workload-subnet" {
  subnet_id                 = azurerm_subnet.azure-test-workload.id
  network_security_group_id = azurerm_network_security_group.azure.id
}

resource "azurerm_public_ip" "azure-bastion" {
  count = var.use_bastion ? 1 : 0
  name                = "AzureBastion-pip"
  location            = azurerm_resource_group.azure.location
  resource_group_name = azurerm_resource_group.azure.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "azure" {
  count = var.use_bastion ? 1 : 0
  name                = "azure-bastion"
  location            = azurerm_resource_group.azure.location
  resource_group_name = azurerm_resource_group.azure.name
  ip_configuration {
    name                 = "azure-bastion-configuration"
    subnet_id            = azurerm_subnet.azure-bastion[0].id
    public_ip_address_id = azurerm_public_ip.azure-bastion[0].id
  }
}

resource "azurerm_public_ip" "azure-test-bastion" {
  count = var.use_bastion ? 1 : 0
  name                = "AzureTestBastion-pip"
  location            = azurerm_resource_group.azure.location
  resource_group_name = azurerm_resource_group.azure.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "azure-test" {
  count               = var.use_bastion ? 1 : 0
  name                = "azure-test-bastion"
  location            = azurerm_resource_group.azure.location
  resource_group_name = azurerm_resource_group.azure.name
  ip_configuration {
    name                 = "azure-bastion-configuration"
    subnet_id            = azurerm_subnet.azure-test-bastion[0].id
    public_ip_address_id = azurerm_public_ip.azure-test-bastion[0].id
  }
}

resource "azurerm_public_ip" "failover" {
  count               = var.failover_public_ip_count
  name                = "test-failover-ip${count.index+1}"
  location            = azurerm_resource_group.azure.location
  resource_group_name = azurerm_resource_group.azure.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
