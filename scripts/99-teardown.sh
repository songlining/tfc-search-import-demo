#!/usr/bin/env bash
# 99-teardown.sh
#
# Resets the demo environment. Deletes the resource group (and everything
# in it) and removes local Terraform state artefacts so the demo can be
# re-run cleanly.

set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f resource-ids.env ]; then
  echo "resource-ids.env not found. Did you run scripts/01-create-clickops-estate.sh?"
  echo "If you need to clean up by hand, list resource groups with:"
  echo "  az group list --query \"[?starts_with(name, 'searchdemo-rg-')].name\" -o tsv"
  exit 1
fi

# shellcheck disable=SC1091
source resource-ids.env

echo "==> Deleting resource group: ${TF_VAR_rg_name}"
az group delete --name "${TF_VAR_rg_name}" --yes --no-wait
echo "    (delete dispatched async; check with: az group show -n ${TF_VAR_rg_name})"

echo "==> Cleaning local Terraform artefacts"
rm -rf terraform/.terraform terraform/.terraform.lock.hcl terraform/terraform.tfstate*
rm -f resource-ids.env

echo "==> Done."
