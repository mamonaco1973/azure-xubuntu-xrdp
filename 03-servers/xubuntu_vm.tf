# ==============================================================================
# Linux VM deployment with Ubuntu account (Xubuntu instance)
# ------------------------------------------------------------------------------
# Generates secure credentials for the 'ubuntu' user, stores them in Key Vault,
# allocates a public IP, provisions a NIC, deploys the VM, and assigns the Key
# Vault Secrets User role to the VM's managed identity.
# ==============================================================================

# ------------------------------------------------------------------------------
# Generate a secure random password for the 'ubuntu' account
# ------------------------------------------------------------------------------
resource "random_password" "ubuntu_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ------------------------------------------------------------------------------
# Store 'ubuntu' credentials in Azure Key Vault as a JSON object
# ------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "ubuntu_secret" {
  name         = "ubuntu-credentials"
  value        = jsonencode({
                  username = "ubuntu"
                  password = random_password.ubuntu_password.result
                })
  key_vault_id = data.azurerm_key_vault.ad_key_vault.id
  content_type = "application/json"
}

# ------------------------------------------------------------------------------
# Allocate a public IP address for the Xubuntu VM
# ------------------------------------------------------------------------------
resource "azurerm_public_ip" "xubuntu_public_ip" {
  name                = "xubuntu-public-ip"
  location            = data.azurerm_resource_group.xubuntu.location
  resource_group_name = data.azurerm_resource_group.xubuntu.name
  domain_name_label   = "xubuntu-${random_string.vm_suffix.result}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ------------------------------------------------------------------------------
# Create a NIC for the Xubuntu VM and associate the public IP
# ------------------------------------------------------------------------------
resource "azurerm_network_interface" "xubuntu_nic" {
  name                = "xubuntu-nic"
  location            = data.azurerm_resource_group.xubuntu.location
  resource_group_name = data.azurerm_resource_group.xubuntu.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.xubuntu_public_ip.id
  }
}

# ------------------------------------------------------------------------------
# Provision the Xubuntu Linux virtual machine
# ------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "xubuntu_instance" {
  name                = "xubuntu-${random_string.vm_suffix.result}"
  location            = data.azurerm_resource_group.xubuntu.location
  resource_group_name = data.azurerm_resource_group.xubuntu.name
  size                = "Standard_D4s_v3"
  admin_username      = "ubuntu"
  admin_password      = random_password.ubuntu_password.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.xubuntu_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = data.azurerm_image.xubuntu_image.id

  boot_diagnostics {
    storage_account_uri = null
  }

  custom_data = base64encode(templatefile(
    "./scripts/custom_data.sh",
    {
      vault_name      = data.azurerm_key_vault.ad_key_vault.name
      domain_fqdn     = var.dns_zone
      netbios         = var.netbios
      force_group     = "mcloud-users"
      realm           = var.realm
      storage_account = azurerm_storage_account.nfs_storage_account.name
    }
  ))

  identity {
    type = "SystemAssigned"
  }
}

# ------------------------------------------------------------------------------
# Grant the VM identity permission to read Key Vault secrets
# ------------------------------------------------------------------------------
resource "azurerm_role_assignment" "vm_lnx_key_vault_secrets_user" {
  scope                = data.azurerm_key_vault.ad_key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.xubuntu_instance.identity[0].principal_id
}
