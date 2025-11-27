# ==============================================================================
# Friendly Password Generator for Azure AD Users
# - Builds passwords as <word>-<number>
# - Stores each user's creds in Azure Key Vault as JSON
# ==============================================================================

# ------------------------------------------------------------------------------
# Word list used to build memorable passwords
# ------------------------------------------------------------------------------
locals {
  memorable_words = [
    "bright", "simple", "orange", "window", "little", "people",
    "friend", "yellow", "animal", "family", "circle", "moment",
    "summer", "button", "planet", "rocket", "silver", "forest",
    "stream", "butter", "castle", "wonder", "gentle", "driver",
    "coffee"
  ]
}

# ------------------------------------------------------------------------------
# AD users (key = username prefix, value = full name)
# ------------------------------------------------------------------------------
locals {
  ad_users = {
    jsmith = "John Smith"
    edavis = "Emily Davis"
    rpatel = "Raj Patel"
    akumar = "Amit Kumar"
  }
}

# ------------------------------------------------------------------------------
# Pick one random word per user
# ------------------------------------------------------------------------------
resource "random_shuffle" "word" {
  for_each     = local.ad_users
  input        = local.memorable_words
  result_count = 1
}

# ------------------------------------------------------------------------------
# Generate a random 6-digit number per user
# ------------------------------------------------------------------------------
resource "random_integer" "num" {
  for_each = local.ad_users
  min      = 100000
  max      = 999999
}

# ------------------------------------------------------------------------------
# Build final passwords as <word>-<number>
# ------------------------------------------------------------------------------
locals {
  passwords = {
    for u, _ in local.ad_users :
    u => "${random_shuffle.word[u].result[0]}-${random_integer.num[u].result}"
  }
}

# ------------------------------------------------------------------------------
# Create an Azure Key Vault secret per user
# ------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "user_secret" {
  for_each = local.ad_users

  name         = "${each.key}-ad-credentials"
  key_vault_id = azurerm_key_vault.ad_key_vault.id

  value = jsonencode({
    username = "${each.key}@${var.dns_zone}"
    password = local.passwords[each.key]
  })

  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}

# ==============================================================================
# Sysadmin account (local AD service account)
# Password also uses friendly format
# ==============================================================================

# ------------------------------------------------------------------------------
# Random word for sysadmin
# ------------------------------------------------------------------------------
resource "random_shuffle" "sys_word" {
  input        = local.memorable_words
  result_count = 1
}

# ------------------------------------------------------------------------------
# Random 6-digit number for sysadmin
# ------------------------------------------------------------------------------
resource "random_integer" "sys_num" {
  min = 100000
  max = 999999
}

# ------------------------------------------------------------------------------
# Store sysadmin credentials in Key Vault
# ------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "sysadmin_secret" {
  name         = "sysadmin-credentials"
  key_vault_id = azurerm_key_vault.ad_key_vault.id

  value = jsonencode({
    username = "sysadmin"
    password = "${random_shuffle.sys_word.result[0]}-${random_integer.sys_num.result}"
  })

  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}

# ==============================================================================
# Admin (domain admin) account using friendly password format
# ==============================================================================

# ------------------------------------------------------------------------------
# Random word for admin
# ------------------------------------------------------------------------------
resource "random_shuffle" "admin_word" {
  input        = local.memorable_words
  result_count = 1
}

# ------------------------------------------------------------------------------
# Random 6-digit number for admin
# ------------------------------------------------------------------------------
resource "random_integer" "admin_num" {
  min = 100000
  max = 999999
}

# ------------------------------------------------------------------------------
# Store admin credentials in Key Vault
# ------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "admin_secret" {
  name         = "admin-ad-credentials"
  key_vault_id = azurerm_key_vault.ad_key_vault.id

  value = jsonencode({
    username = "Admin@${var.dns_zone}"
    password = "${random_shuffle.admin_word.result[0]}-${random_integer.admin_num.result}"
  })

  depends_on   = [azurerm_role_assignment.kv_role_assignment]
  content_type = "application/json"
}
