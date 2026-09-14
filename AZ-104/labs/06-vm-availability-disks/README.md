# Lab 06 — VM Deployment, Availability Zones & Managed Disks

**AZ-104 domain:** Deploy and manage Azure compute resources (20–25%) — Create and configure virtual machines
**Cost:** REAL — ~$0.01/hr for the VM (`Standard_B1s`) plus ~$0.02/day for a small Premium SSD managed disk. This is the **first AZ-104 lab with genuine hourly billing** (Labs 01-05 were governance-only and free). Delete it the same day you deploy it.
**Time:** ~20 minutes

## What you'll build

A Linux VM (`Standard_B1s`) with its own VNet/subnet/NSG/NIC/public IP, pinned to a specific **availability zone** via the VM's `zones` property, using a **Premium SSD managed OS disk**, with **encryption at host** enabled. AZ-900 Lab 9 built a VM and stopped at "here's what a VM needs." This lab starts from there and asks the admin-level question: *where* does this VM live for resiliency, and what's actually protecting its disk?

You'll need an SSH key pair. If you don't have one:

```bash
ssh-keygen -t ed25519 -C "az104-lab06" -f ~/.ssh/id_ed25519 -N ""
```

## Deploy

```bash
az group create --name rg-az104-lab06 --location eastus

az deployment group create \
  --resource-group rg-az104-lab06 \
  --template-file main.bicep \
  --parameters adminPublicKey="$(cat ~/.ssh/id_ed25519.pub)"
```

> If deployment fails with an `EncryptionAtHost` feature error, your subscription needs the feature registered first:
> ```bash
> az feature register --namespace Microsoft.Compute --name EncryptionAtHost
> az feature show --namespace Microsoft.Compute --name EncryptionAtHost --query properties.state
> ```
> Registration can take a few minutes to move from `Registering` to `Registered`.

## Verify

```bash
az vm show --resource-group rg-az104-lab06 --name vm-az104lab06 \
  --query "{name:name, size:hardwareProfile.vmSize, zones:zones, provisioningState:provisioningState}" -o table

az disk list --resource-group rg-az104-lab06 \
  --query "[].{name:name, sku:sku.name, sizeGB:diskSizeGB}" -o table
```

In the portal: **rg-az104-lab06 → vm-az104lab06 → Overview** shows the assigned zone next to the region, and **Disks** shows the OS disk's `Premium_LRS` SKU.

## Manual tasks (can't be done by Bicep)

1. **Resize the VM.**
   ```bash
   az vm resize --resource-group rg-az104-lab06 --name vm-az104lab06 --size Standard_B2s
   ```
   This causes a restart and brief downtime. Azure only offers sizes available on the VM's **current hardware cluster** — the same constraint the portal's **Size** blade shows as a filtered list, not every VM size that exists. Sometimes the size you want isn't offered at all from the current cluster, and the only path is to stop/deallocate the VM and let Azure place it on different hardware when it starts back up.

2. **Move the VM to a different resource group.**
   ```bash
   az resource move --destination-group rg-az104-lab06-moved \
     --ids $(az vm show --resource-group rg-az104-lab06 --name vm-az104lab06 --query id -o tsv)
   ```
   Azure validates and moves the VM's dependency graph (NIC, disk) together — but a move can still fail if you only list the VM's ID and a dependency isn't eligible to move with it, or if the resource type doesn't support cross-subscription moves at all. Check `az resource list-moved-resources` or just read the error; it names exactly what blocked the move.

## Clean up

```bash
az group delete --name rg-az104-lab06 --yes --no-wait
```

Deleting the resource group removes the VM, its managed disk, NIC, NSG, public IP, and VNet together — everything in this lab lives in one RG, so there's no separate ordering to worry about.

## Lecture talking points

- **Availability zone vs. availability set — genuinely different blast radii, and the exam tests the distinction directly.** A zone is a physically separate datacenter facility within the region (its own power, cooling, network) — it protects against a whole-datacenter failure. An availability set spreads VMs across fault domains and update domains **within one datacenter** — it protects against a single rack or host failing, not the datacenter itself. A VM can be placed in a zone or an availability set, but never both at once, because they're solving problems at two different scales.
- **Resizing isn't unlimited.** The target size has to be available on the VM's current hardware cluster. The portal's Size blade filters to what's actually offered for exactly this reason — sometimes getting the size you want means stopping the VM and letting Azure re-place it on hardware that supports it.
- **Encryption at host, briefly, not a deep dive.** It encrypts the temp disk and the OS/data disk caches at the host level. That's different from (and complementary to) Azure Disk Encryption, which is OS-level BitLocker/dm-crypt running inside the guest. Know they're two different controls; ADE itself isn't this lab's focus.
- **Direct callback to AZ-900 Lab 9.** "Last course, you just created a VM. This course, you're choosing its placement and resize path deliberately" — same four resource categories (compute/storage/networking/region), now with resiliency and disk tier as explicit decisions instead of defaults.
- **This is the first AZ-104 lab with real hourly billing.** Labs 01-05 (RBAC, Policy) are governance constructs with no compute attached — $0 either way. This one bills by the second the moment it's running. Naming that out loud before deploying is the discipline this repo keeps building on.

## What you learned

By completing this lab, you can now:

- Pin a VM to a specific **availability zone** and explain why that's mutually exclusive with availability-set placement on the same VM.
- Distinguish an availability zone's blast radius (datacenter-level) from an availability set's (rack/host-level within one datacenter).
- Resize a running VM with `az vm resize`, and explain why the offered sizes are constrained by the VM's current hardware cluster.
- Move a VM (and its dependency graph) between resource groups with `az resource move`, and recognize when a move can fail.
- Explain what `encryptionAtHost` protects and how it differs from Azure Disk Encryption.
