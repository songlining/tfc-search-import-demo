# Teardown Process

Use this runbook to reset the demo after a rehearsal or live presentation.

There are two different cleanup goals:

1. Remove resources from Terraform state but keep Azure resources for another Search & Import rehearsal.
2. Delete the Azure resources and clean local runtime files.

## Before You Start

Run from the repo root unless a command says otherwise:

```bash
cd tfc-search-import-demo
```

If `resource-ids.env` exists, source it before Terraform state commands:

```bash
source ./resource-ids.env
```

## Option A: Reset Terraform State Only

Use this when resources were imported into HCP Terraform state and you want them to appear unmanaged again in the Search & Import UI.

```bash
cd tfc-search-import-demo
source ./resource-ids.env
cd terraform/
terraform state rm -ignore-remote-version \
  azurerm_resource_group.clickops_0 \
  azurerm_storage_account.clickops_0 \
  azurerm_virtual_network.clickops_0
```

The `-ignore-remote-version` flag is useful when your local Terraform CLI is older than the remote HCP Terraform workspace version.

Move active generated config out of the Terraform load path before rerunning the demo:

```bash
cd tfc-search-import-demo
mv terraform/generated.tf terraform/generated.latest.tf.example
```

`generated*.tf` and `generated*.tf.example` are ignored by git.

## Option B: Delete Azure Resources

Use this when you want to destroy the demo estate and start fresh later.

```bash
cd tfc-search-import-demo
./scripts/99-teardown.sh
```

The teardown script:

- Reads `resource-ids.env`.
- Dispatches an asynchronous Azure resource group delete.
- Removes local Terraform runtime artifacts.
- Removes `resource-ids.env`.

The Azure delete is asynchronous. Check deletion status with:

```bash
az group show -n <resource-group-name>
```

If `resource-ids.env` is missing, list likely demo resource groups manually:

```bash
az group list --query "[?starts_with(name, 'searchdemo-rg-')].name" -o tsv
```

Then delete the correct resource group:

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

## Start Fresh After Teardown

After Azure deletion completes, recreate the ClickOps estate:

```bash
cd tfc-search-import-demo
./scripts/01-create-clickops-estate.sh
source ./resource-ids.env
cd terraform/
terraform query
```
