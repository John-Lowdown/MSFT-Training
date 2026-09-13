# Lab 2 — Storage Redundancy (LRS / ZRS / GRS)

**AZ-900 domain:** Core Services — Storage
**Cost:** near-$0 (empty storage accounts; delete right after the demo)
**Time:** ~15 minutes

## What you'll build
Three storage accounts side-by-side, identical except for their redundancy SKU (`Standard_LRS`, `Standard_ZRS`, `Standard_GRS`) — a direct, clickable comparison of the three tiers AZ-900 tests most.

## Deploy

```bash
az group create --name rg-az900-lab02 --location eastus

az deployment group create \
  --resource-group rg-az900-lab02 \
  --template-file main.bicep \
  --parameters storageBaseName=az900lab02
```

> Storage account names are globally unique across all of Azure. If deployment fails with a name conflict, change `storageBaseName` to something more unique (e.g. add your initials) and redeploy.

## Verify

```bash
az storage account list --resource-group rg-az900-lab02 --query "[].{name:name, sku:sku.name}" -o table
```

In the portal, open any of the three accounts → **Data protection → Redundancy** to see the tier and, for the GRS account, the paired secondary region.

## Clean up

```bash
az group delete --name rg-az900-lab02 --yes --no-wait
```

## Lecture talking points

- **LRS** = 3 synchronous copies in a single datacenter. Survives a rack or drive failure, not a datacenter-level disaster.
- **ZRS** = 3 synchronous copies across availability zones in the same region. Survives a datacenter-level disaster within that region, not a regional disaster.
- **GRS** = LRS in the primary region + async replication to the Microsoft-paired secondary region. Data in the secondary region is not readable unless you fail over (or pay extra for **RA-GRS**, which adds a read-only endpoint in the secondary region at all times) — this "GRS vs RA-GRS" distinction is a favorite exam distractor.
- **This is a durability spectrum, not a performance or availability spectrum.** Redundancy tier affects how many copies of your data exist and where; it does not by itself determine uptime SLA in the way a load balancer or Availability Set does — don't let students conflate the two.
- **Cost order:** LRS < ZRS ≈ GRS < GZRS/RA-GZRS, roughly — more copies and more distance cost more. This ties directly into Module 6 (pricing).
- Point out `supportsHttpsTrafficOnly` and `minimumTlsVersion` in the template — a quick, free hook into Module 5 (security) without adding a new resource.
