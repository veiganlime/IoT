terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.0.4"
}

provider "azurerm" {

  subscription_id = "c4c1dd3f-4f33-487a-ac21-e8c5f83b1c58"
  features {

  }
  skip_provider_registration = true
}

resource "azurerm_resource_group" "rg_cps" {

  name     = "rg_cps_praktikum"
  location = "West Europe"
}

resource "azurerm_storage_account" "storageaccount" {
  name                     = "sacps"
  resource_group_name      = azurerm_resource_group.rg_cps.name
  location                 = azurerm_resource_group.rg_cps.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storagecontainersource" {
  name                  = "sourcecontcps"
  storage_account_name  = azurerm_storage_account.storageaccount.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "storagecontainersink" {
  name                  = "sinkcontcps"
  storage_account_name  = azurerm_storage_account.storageaccount.name
  container_access_type = "private"
}

resource "azurerm_data_factory" "adf" {
  name                = "adfcpspraktikum"
  location            = azurerm_resource_group.rg_cps.location
  resource_group_name = azurerm_resource_group.rg_cps.name
}




resource "azurerm_virtual_network" "vmcps" {
  name                = "cpsnetwork"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_cps.location
  resource_group_name = azurerm_resource_group.rg_cps.name
}

resource "azurerm_subnet" "subnetcps" {
  name                 = "cpssubnet"
  resource_group_name  = azurerm_resource_group.rg_cps.name
  virtual_network_name = azurerm_virtual_network.vmcps.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_public_ip" "cps_public_ip" {
  name                = "vm_public_ip"
  resource_group_name = azurerm_resource_group.rg_cps.name
  location            = azurerm_resource_group.rg_cps.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "cpsnic"
  location            = azurerm_resource_group.rg_cps.location
  resource_group_name = azurerm_resource_group.rg_cps.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetcps.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.cps_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vmcps" {
  name                = "vmcps"
  resource_group_name = azurerm_resource_group.rg_cps.name
  location            = azurerm_resource_group.rg_cps.location
  size                = "Standard_F2"
  admin_username      = "lime"
  admin_password      = "MyAdminPassword!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

