# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# Virtual Network
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# PostgreSQL Server
resource "azurerm_postgresql_server" "example" {
  name                = "example-postgres-server"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "GP_Gen5_2"
  storage_mb          = 51200  # 50 GB
  administrator_login = var.db_username
  administrator_login_password = var.db_password
  version             = "11"

  tags = {
    environment = "Production"
  }
}

# Firewall Rule to Allow Access
resource "azurerm_postgresql_firewall_rule" "example" {
  name                = "example-firewall-rule"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Database
resource "azurerm_postgresql_database" "example" {
  name                = "mail_db"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_server.example.name
  charset             = "UTF8"
  collation           = "English_United States.1252"subscription_id
}

# Virtual Machine
resource "azurerm_virtual_machine" "example" {
  name                  = "app-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "app-vm"
    admin_username = "adminuser"

    admin_password = var.ssh_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Network Security Group
resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "PostgreSQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualMachineIP"
    destination_address_prefix = azurerm_postgresql_server.example.fqdn
    destination_port_range     = "5432"
  }
}

# Associate NSG with the Virtual Machine's Network Interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}