#!/bin/bash
# ==============================================================================
# Destroy Script for Xubuntu XRDP Project on Azure
# Purpose:
#   - Removes all Xubuntu XRDP project resources deployed in Azure.
#   - Destroys server layer first, then directory layer.
#   - Deletes the latest Xubuntu image and all older images.
# Notes:
#   - This will permanently delete all deployed resources.
#   - Assumes Azure CLI and Terraform are installed and authenticated.
# ==============================================================================

set -e

# ------------------------------------------------------------------------------
# Fetch latest Xubuntu image from the packer resource group
# ------------------------------------------------------------------------------
xubuntu_image_name=$(az image list \
  --resource-group xubuntu-project-rg \
  --query "[?starts_with(name, 'xubuntu_image')]|sort_by(@, &name)[-1].name" \
  --output tsv)

echo "Using latest image: $xubuntu_image_name"

if [ -z "$xubuntu_image_name" ]; then
  echo "ERROR: No Xubuntu image found in xubuntu-project-rg."
  exit 1
fi

# ------------------------------------------------------------------------------
# Phase 1: Destroy server layer (VMs, networking, bindings)
# ------------------------------------------------------------------------------
cd 03-servers

vault=$(az keyvault list \
  --resource-group mcloud-project-rg \
  --query "[?starts_with(name, 'ad-key-vault')].name | [0]" \
  --output tsv)

echo "Using Key Vault: $vault"

terraform init
terraform destroy \
  -var="vault_name=$vault" \
  -var="xubuntu_image_name=$xubuntu_image_name" \
  -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Delete all Xubuntu images in xubuntu-project-rg
# ------------------------------------------------------------------------------
az image list \
  --resource-group xubuntu-project-rg \
  --query "[].name" \
  -o tsv | while read -r IMAGE; do
    echo "Deleting image: $IMAGE"
    az image delete \
      --name "$IMAGE" \
      --resource-group xubuntu-project-rg \
      || echo "Failed to delete $IMAGE; skipping"
done

# ------------------------------------------------------------------------------
# Phase 2: Destroy directory layer (Key Vault, baseline infra)
# ------------------------------------------------------------------------------
cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..
echo "NOTE: Xubuntu XRDP project resources have been successfully destroyed."