#!/bin/bash
# ==================================================================================================
# Bootstrap Script for Mini Active Directory Deployment (Azure)
# Purpose:
#   - Validates the environment and dependencies before provisioning.
#   - Deploys Active Directory infrastructure in two phases:
#       1. Directory layer (Key Vault, AD base infra)
#       2. Server layer (Linux VM for Samba AD, domain join, secrets)
#   - Ensures failures are caught early with explicit exit conditions.
#
# Notes:
#   - Assumes `az` (Azure CLI) and `terraform` are installed and authenticated.
#   - Assumes `check_env.sh` validates required environment variables and tools.
#   - Automatically discovers the Key Vault name created in Phase 1 and passes
#     it into Phase 2 as a Terraform variable.
# ==================================================================================================

set -e  # Exit immediately on any unhandled command failure

# --------------------------------------------------------------------------------------------------
# Pre-flight Check: Validate environment
# Runs custom environment validation script (`check_env.sh`) to ensure:
#   - Azure CLI is logged in and subscription is set
#   - Terraform is installed
#   - Required variables (subscription ID, tenant ID, etc.) are present
# --------------------------------------------------------------------------------------------------
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# --------------------------------------------------------------------------------------------------
# Phase 1: Deploy Directory Layer
# - Provisions foundational resources such as Key Vault and base AD infrastructure.
# - Directory Terraform code is stored under ./01-directory.
# --------------------------------------------------------------------------------------------------
cd 01-directory

terraform init   # Initialize Terraform working directory (download providers/modules)
terraform apply -auto-approve   # Deploy Key Vault and other directory resources

# Error handling for Terraform apply
if [ $? -ne 0 ]; then
  echo "ERROR: Terraform apply failed in 01-directory. Exiting."
  exit 1
fi
cd ..

# Next Phase - Build packer

#cd 02-packer                        # Change to Packer directory
#packer init .                       # Initialize Packer plugins
#packer build \
#  -var="client_id=$ARM_CLIENT_ID" \
#  -var="client_secret=$ARM_CLIENT_SECRET" \
#  -var="subscription_id=$ARM_SUBSCRIPTION_ID" \
#  -var="tenant_id=$ARM_TENANT_ID" \
#  -var="resource_group=xubuntu-project-rg" \
#  xubuntu_image.pkr.hcl             # Packer HCL template for Linux image

#cd ..                               # Return to 02-packer

#exit 0

# --------------------------------------------------------------------------------------------------
# Phase 2: Deploy Server Layer
# - Provisions Samba-based AD Domain Controller (Linux VM).
# - Discovers the Key Vault name from Azure (matching "ad-key-vault*") and passes
#   it into Terraform as a variable.
# --------------------------------------------------------------------------------------------------
cd 03-servers

#-------------------------------------------------------------------------------
# Fetch latest 'xubuntu_image' from the packer resource group
#-------------------------------------------------------------------------------

xubuntu_image_name=$(az image list \
  --resource-group xubuntu-project-rg \
  --query "[?starts_with(name, 'xubuntu_image')]|sort_by(@, &name)[-1].name" \
  --output tsv)

echo "NOTE: Using the latest image ($xubuntu_image_name) in xubuntu-project-rg."

# Fail-fast if no xubuntu_image is found
if [ -z "$xubuntu_image_name" ]; then
  echo "ERROR: No image with the prefix 'xubuntu_image' was found in 'xubuntu-project-rg'. Exiting."
  exit 1
fi

# Query Azure for the Key Vault created in Phase 1 (first matching "ad-key-vault*")
vault=$(az keyvault list \
  --resource-group xubuntu-network-rg \
  --query "[?starts_with(name, 'ad-key-vault')].name | [0]" \
  --output tsv)

echo "NOTE: Key vault for secrets is $vault"

terraform init   # Initialize Terraform in server layer
terraform apply \
    -var="vault_name=$vault" \
    -var="xubuntu_image_name=$xubuntu_image_name" \
    -auto-approve   

cd ..
