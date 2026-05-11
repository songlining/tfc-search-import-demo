# Demo Process

This runbook walks through the HCP Terraform Search & Import demo from a clean checkout to generated Terraform starter configuration.

## What The Demo Shows

1. Create a small Azure estate outside Terraform.
2. Use HCP Terraform to search Azure for those unmanaged resources.
3. Show the Search & Import UI list, IaC status, resource selection, and generated starter configuration.
4. Generate the same starter Terraform configuration locally with the CLI.
5. Optionally review, clean, apply, and verify the imported resources.

## Prerequisites

- Azure CLI authenticated to the subscription you want to use.
- Terraform CLI `>= 1.14.0`.
- HCP Terraform workspace created for the demo.
- Azure OIDC trust configured for that HCP Terraform workspace. Use `scripts/02-bootstrap-tfc-oidc.sh` if you want the helper script to create it.

Set these values for your environment:

```bash
export TFC_ORG="<your-hcp-terraform-org>"
export TFC_WORKSPACE="search-import-demo"
export TFC_PROJECT="Default Project"
```

Update `terraform/main.tf` so the `cloud` block points at the same HCP Terraform organization and workspace.

## 1. Confirm Local Authentication

```bash
az account show --query "{name:name, id:id, tenantId:tenantId, user:user.name}" -o json
terraform login
cd tfc-search-import-demo/terraform
terraform init
terraform validate
```

## 2. Create The Unmanaged Azure Estate

```bash
cd tfc-search-import-demo
./scripts/01-create-clickops-estate.sh
```

The script creates:

- One resource group.
- One storage account.
- One virtual network.

It writes `resource-ids.env`, which captures the generated names and resource IDs. The suffix changes on every run to avoid name collisions.

Source that file before Terraform commands that need the generated resource names:

```bash
source ./resource-ids.env
```

The most important value for Search & Import is `TF_VAR_rg_name`; `terraform/search.tfquery.hcl` uses it to scope storage account and virtual network discovery.

## 3. Show The Existing Resources

In the Azure portal, open the generated resource group from `resource-ids.env`.

Point out:

- The resources already exist in Azure.
- They were created outside Terraform.
- They are tagged `created_by=clickops` and `demo=search-import-demo`.

## 4. Show The Terraform Search Configuration

Open `terraform/main.tf`. It should contain only the HCP Terraform workspace and Azure provider configuration. There should be no Azure `resource` or `import` blocks yet.

Open `terraform/search.tfquery.hcl`. It contains provider-backed `list` blocks for:

- `azurerm_resource_group`
- `azurerm_storage_account`
- `azurerm_virtual_network`

## 5. Run The Query From The CLI

Make sure no previous generated config is active in the Terraform directory. Terraform loads every `*.tf` file before it runs the query, so an old `generated.tf` can break discovery.

```bash
cd tfc-search-import-demo
if [ -f terraform/generated.tf ]; then
	mv terraform/generated.tf terraform/generated.latest.tf.example
fi
```

```bash
cd tfc-search-import-demo
source ./resource-ids.env
cd terraform/
terraform query
```

Expected result: HCP Terraform runs a remote query and returns the resource group, storage account, and virtual network.

Example output shape:

```text
list.azurerm_resource_group.clickops   name=searchdemo-rg-1234,subscription_id=...   searchdemo-rg-1234
list.azurerm_virtual_network.clickops  name=searchdemo-vnet-1234,resource_group_name=searchdemo-rg-1234,subscription_id=...   searchdemo-vnet-1234
list.azurerm_storage_account.clickops  name=searchdemosa1234,resource_group_name=searchdemo-rg-1234,subscription_id=...   searchdemosa1234
```

If the query exits with status 1 after the remote run starts, first check that you sourced `resource-ids.env` in the current shell and that no previous `generated.tf` is still active in the Terraform directory.

## 6. Show Selection In The HCP Terraform UI

Open the Search & Import page for your workspace:

```text
https://app.terraform.io/app/<your-hcp-terraform-org>/workspaces/search-import-demo/search
```

In the UI:

1. Open the latest finished query.
2. Confirm it found the three Azure resources.
3. Select the three resources.
4. Click `Generate Starter Configuration`.
5. Show the generated `resource` and identity-based `import` blocks.

Talk track:

> Terraform searched Azure, found brownfield resources, and gave me a list to review. I choose what comes under management. That matters because real estates are messy; import should be a controlled selection, not a blind sweep.

## 7. Generate The File From The CLI

After showing UI selection, switch back to the terminal and generate a local file from the same query configuration:

```bash
cd tfc-search-import-demo
source ./resource-ids.env
cd terraform/
rm -f generated.tf
terraform query -generate-config-out=generated.tf
```

Show the generated file:

```bash
ls -la generated.tf
sed -n '1,180p' generated.tf
```

Point out that it contains both generated `resource` blocks and identity-based `import` blocks.

Talk track:

> The UI gave us the review and selection workflow. The CLI gives us the artifact: real Terraform code on disk, ready for review, cleanup, and version control.

## 8. Review And Clean Generated Configuration

Generated configuration is starter configuration. Review it before applying.

With AzureRM `4.72.0`, generated config may need cleanup such as:

- Remove `flow_timeout_in_minutes = 0` from `azurerm_virtual_network`.
- Convert generated virtual network `subnet = [{ ... }]` syntax into a standard `subnet { ... }` block.
- Remove generated subnet-only values such as `id`, `route_table_id = ""`, and `security_group = ""`.
- Remove `change_feed_retention_in_days = 0` from `azurerm_storage_account.blob_properties`.

Do not leave any generated `.tf` file in place before starting a fresh demo, or Terraform will treat it as active configuration.

## 9. Optional: Apply The Import

After reviewing and cleaning `generated.tf`:

```bash
terraform validate
terraform apply
```

The expected import shape is:

```text
Resources: 3 imported, 0 added, ...
```

Provider-normalized in-place updates can appear during the first import apply. Run a follow-up plan to prove the final configuration is stable.

## 10. Optional: Prove The Resources Are Managed

```bash
terraform state list
terraform plan -detailed-exitcode
```

Expected state addresses:

```text
azurerm_resource_group.clickops_0
azurerm_storage_account.clickops_0
azurerm_virtual_network.clickops_0
```
