# HCP Terraform Search & Import Demo

> Outcome line: "Every resource you import is one more resource that's recoverable from code."

This repo is a generic, repeatable demo of HCP Terraform Search & Import for an existing Azure estate. It creates a small set of Azure resources outside Terraform, asks HCP Terraform to search for them, shows selection and generated starter configuration in the HCP Terraform UI, then uses the CLI to generate the same Terraform starter file locally.

## What This Demo Proves

1. Cloud estates often contain resources that are not managed by Terraform.
2. HCP Terraform can search Azure for existing resources using provider-backed `list` blocks.
3. The Search & Import UI lets an operator review discovered resources, see IaC status, select resources, and generate starter Terraform code.
4. The CLI can generate the same starter Terraform code into a local `generated.tf` file.
5. After import, resources are recoverable and governable through Terraform state and normal plan/apply workflows.

## Repo Layout

```text
.
├── docs/
│   ├── demo-process.md                # end-to-end demo runbook
│   └── teardown-process.md            # reset and cleanup runbook
├── scripts/
│   ├── 01-create-clickops-estate.sh   # create unmanaged Azure resources
│   ├── 02-bootstrap-tfc-oidc.sh        # create Azure OIDC trust for HCP Terraform
│   └── 99-teardown.sh                 # delete the Azure estate and local runtime files
├── terraform/
│   ├── main.tf                        # HCP Terraform workspace + Azure provider
│   └── search.tfquery.hcl             # Search & Import list blocks
└── README.md
```

Generated runtime files are intentionally not source-controlled:

- `resource-ids.env`
- `tfc-oidc.env`
- `terraform/generated.tf`
- `terraform/generated*.tf.example`
- `terraform/.terraform/`

## Start Here

- Demo process: [docs/demo-process.md](docs/demo-process.md)
- Teardown process: [docs/teardown-process.md](docs/teardown-process.md)

## Required Configuration

This repo defaults to the demo author's HCP Terraform organization. Before running the demo in your own account, update `terraform/main.tf` with your HCP Terraform organization:

```hcl
cloud {
  # This is the demo author's HCP Terraform organization.
  # Change this to your own organization before running the demo elsewhere.
  organization = "lab-larry"

  workspaces {
    name = "search-import-demo"
  }
}
```

Set these environment variables when using the OIDC bootstrap helper:

```bash
export TFC_ORG="<your-hcp-terraform-org>"
export TFC_WORKSPACE="search-import-demo"
export TFC_PROJECT="Default Project"
```

The bootstrap helper uses your active Azure CLI account to discover the tenant and subscription:

```bash
az account show --query "{name:name, id:id, tenantId:tenantId, user:user.name}" -o json
```

## Azure OIDC Setup

This demo is designed for HCP Terraform dynamic provider credentials for Azure. The helper script creates:

1. An Azure AD application and service principal.
2. Federated identity credentials for HCP Terraform `plan` and `apply` run phases.
3. A `Contributor` role assignment on the active Azure subscription.
4. A local `tfc-oidc.env` file with the HCP Terraform workspace environment variables to set.

Run it from an Azure CLI session that has permission to create app registrations and assign roles:

```bash
TFC_ORG="<your-hcp-terraform-org>" ./scripts/02-bootstrap-tfc-oidc.sh
```

Set the printed values as environment variables on your HCP Terraform workspace:

| Key | Purpose |
| --- | --- |
| `TFC_AZURE_PROVIDER_AUTH` | Tells HCP Terraform to mint Azure OIDC credentials for the run. |
| `TFC_AZURE_RUN_CLIENT_ID` | Azure AD app/client ID that HCP Terraform impersonates. |
| `ARM_TENANT_ID` | Azure tenant ID. |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID. |
| `ARM_USE_OIDC` | Tells the AzureRM provider to use OIDC auth. |

No Azure client secret is required or stored in HCP Terraform.

## Why `resource-ids.env` Exists

`scripts/01-create-clickops-estate.sh` creates resources with a changing suffix to avoid Azure name collisions. It writes the generated names and IDs to `resource-ids.env`.

Source that file before running Terraform query commands:

```bash
source ./resource-ids.env
```

The query file uses `TF_VAR_rg_name` from that env file to scope discovery for storage accounts and virtual networks.

## Common Failure Modes

| Symptom | Cause | Fix |
| --- | --- | --- |
| `terraform init` points at the wrong HCP Terraform org | `terraform/main.tf` still has the demo author's org | Replace `lab-larry` with your HCP Terraform org. |
| Query exits 1 after the remote run starts | `resource-ids.env` was not sourced in the current shell | Run `source ./resource-ids.env`, then rerun `terraform query`. |
| Search & Import page shows no resources | Query did not run against the generated resource group | Source `resource-ids.env`, run `terraform query`, then refresh the Search & Import page. |
| Azure auth error in query run | Workspace OIDC variables or federated credentials are missing | Run `scripts/02-bootstrap-tfc-oidc.sh`, then set the five workspace env vars from `tfc-oidc.env`. |
| `AADSTS70021` | Federated credential subject does not match the HCP Terraform org/project/workspace/run phase | Confirm `TFC_ORG`, `TFC_PROJECT`, and `TFC_WORKSPACE`, then recreate the federated credentials. |
| `generated.tf` already exists | Terraform refuses to overwrite generated config | Move or remove `terraform/generated.tf`, then rerun `terraform query -generate-config-out=generated.tf`. |
| Generated config fails validation | Provider-generated starter config includes attributes that need cleanup | Follow the cleanup notes in [docs/demo-process.md](docs/demo-process.md). |
| Resources show `Managed` instead of `Unmanaged` | They are already in this workspace's state | Follow the state reset steps in [docs/teardown-process.md](docs/teardown-process.md). |

## Public Publishing Notes

This repository intentionally avoids committing generated environment files, Terraform state, generated import config, and provider downloads. Before publishing your own copy, choose an appropriate license and confirm the HCP Terraform organization in `terraform/main.tf` is not a private/internal org.
