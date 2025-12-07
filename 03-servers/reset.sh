xubuntu_image_name=$(az image list \
  --resource-group xubuntu-project-rg \
  --query "[?starts_with(name, 'xubuntu_image')]|sort_by(@, &name)[-1].name" \
  --output tsv)

echo "NOTE: Using latest Xubuntu image: $xubuntu_image_name"

vault=$(az keyvault list \
  --resource-group xubuntu-network-rg \
  --query "[?starts_with(name, 'ad-key-vault')].name | [0]" \
  --output tsv)

echo "NOTE: Using Key Vault: $vault"

terraform destroy \
  -var="vault_name=$vault" \
  -var="xubuntu_image_name=$xubuntu_image_name" \
  -auto-approve

terraform apply \
  -var="vault_name=$vault" \
  -var="xubuntu_image_name=$xubuntu_image_name" \
  -auto-approve

