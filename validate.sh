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
# Lookup Windows VM Public FQDN
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
# Lookup Xubuntu Public FQDN
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


  # ------------------------------------------------------------------------
  # Wait for SSH (port 22) on Xubuntu instance
  # ------------------------------------------------------------------------
  max_attempts=30
  attempt=1
  sleep_secs=10

  echo "INFO: Waiting for SSH (port 22) on $xubuntu_dns ..."

  while [ "$attempt" -le "$max_attempts" ]; do
    if timeout 5 bash -c "echo > /dev/tcp/$xubuntu_dns/22" \
      2>/dev/null; then
      echo "SUCCESS: SSH is reachable on $xubuntu_dns:22"
      break
    fi

    echo "INFO: Attempt $attempt/$max_attempts - SSH not ready, " \
"sleeping ${sleep_secs}s ..."
    attempt=$((attempt + 1))
    sleep "$sleep_secs"
  done

  if [ "$attempt" -gt "$max_attempts" ]; then
    echo "WARNING: Timed out waiting for SSH on $xubuntu_dns:22"
  fi
fi
