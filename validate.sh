#!/bin/bash
# --------------------------------------------------------------------------------
# Description:
#   Queries Azure for public IP resources in a target resource group and prints
#   their fully qualified DNS names. Replaces AWS EC2 lookups with Azure CLI.
#
# Requirements:
#   - Azure CLI installed and logged in
#   - Public IPs must exist in RG: xubuntu-project-rg
#   - Public IP resource names:
#       * windows-vm-public-ip
#       * xubuntu-public-ip
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------------
RESOURCE_GROUP="xubuntu-project-rg"

# --------------------------------------------------------------------------------
# Lookup Windows VM Public DNS
# --------------------------------------------------------------------------------
windows_dns=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "windows-vm-public-ip" \
  --query "dnsSettings.fqdn" \
  --output tsv 2>/dev/null)

if [ -z "$windows_dns" ]; then
  echo "ERROR: No DNS label found for windows-vm-public-ip"
else
  echo "NOTE: Windows Admin Instance FQDN: $windows_dns"
fi

# --------------------------------------------------------------------------------
# Lookup Xubuntu Public DNS
# --------------------------------------------------------------------------------
xubuntu_dns=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "xubuntu-public-ip" \
  --query "dnsSettings.fqdn" \
  --output tsv 2>/dev/null)

if [ -z "$xubuntu_dns" ]; then
  echo "ERROR: No DNS label found for xubuntu-public-ip"
else
  echo "NOTE: Xubuntu Instance FQDN: $xubuntu_dns"
fi
