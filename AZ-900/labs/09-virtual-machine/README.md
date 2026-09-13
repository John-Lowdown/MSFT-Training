# Lab 9 — Virtual Machine Basics

**AZ-900 domain:** Azure Architecture & Services — Compute
**Cost:** ~$0.01–0.05 for a short demo on `Standard_B1s` — **the only lab in this repo with a genuinely non-zero cost.** Every other lab is free or a fraction of a cent. Delete this one immediately after the demo.
**Time:** ~15 minutes

## What you'll build

A single Linux virtual machine (`Standard_B1s`, the cheapest widely-available burstable size), with its own VNet/subnet, NSG, public IP, and NIC — deliberately built so every one of the "four resource categories a VM actually needs" (compute, storage, networking, region/resilience) is visible as its own resource in the template, matching how the guide's Module 3 breaks it down.

You'll need an SSH key pair. If you don't have one:

```bash
ssh-keygen -t ed25519 -C "az900-lab09" -f ~/.ssh/id_ed25519 -N ""
```

## Deploy

```bash
az group create --name rg-az900-lab09 --location eastus

az deployment group create \
  --resource-group rg-az900-lab09 \
  --template-file main.bicep \
  --parameters adminPublicKey="$(cat ~/.ssh/id_ed25519.pub)"
```

## Verify

```bash
az vm show --resource-group rg-az900-lab09 --name vm-az900-lab09 --query "{name:name, size:hardwareProfile.vmSize, provisioningState:provisioningState}" -o table

IP=$(az deployment group show --resource-group rg-az900-lab09 --name main --query "properties.outputs.publicIpAddress.value" -o tsv)
ssh azureuser@$IP
```

In the portal: **rg-az900-lab09 → vm-az900-lab09 → Overview** shows the size, and clicking through to the OS disk and network interface shows the storage and networking pieces separately — three resources, one VM, exactly the "four categories" breakdown from the module this lab supports.

## Clean up

**Delete this immediately after the demo — it's the only lab in this repo actively billing by the second while it exists.**

```bash
az group delete --name rg-az900-lab09 --yes --no-wait
```

## Lecture talking points

- **This is the lab that makes "what a VM actually needs" concrete.** Four categories, four things to point at in the portal: compute (the size/SKU you picked), storage (the OS disk, a separate manageable resource), networking (the NIC, connected to a subnet, with an optional public IP), and region (where you deployed it — no availability set or zone here, since a single throwaway VM doesn't need resilience configuration, but say that gap out loud).
- **Say the cost difference out loud before deploying.** Every other lab in this repo is $0. This one bills by the second on a real VM SKU. It's trivially cheap for a 15-minute demo, but naming that explicitly is the whole point of the discipline this repo tries to teach — always know what's billing before you deploy it.
- **Key-based auth, not a password, and say why.** `disablePasswordAuthentication: true` is set deliberately. This is a real security default, not just a lab convenience — tie it back to Module 5's defense-in-depth and identity content, and to why the shared responsibility model puts OS-level hardening squarely on the customer for IaaS.
- **The NSG here is the same pattern as Lab 3, on a real target this time.** `sshSourceAddressPrefix` defaults to `*` (any address) purely for lab simplicity — call this out as exactly the kind of default you would never ship in production. A good live moment: redeploy with `--parameters sshSourceAddressPrefix=<your-own-IP>/32` and show the rule tighten in the portal.
- **Standard SKU public IP, not Basic — mention why.** Microsoft has retired the Basic SKU for new public IPs; this is a small, easy-to-miss detail that trips up older tutorials and blog posts still teaching Basic.
- **Marketplace image references drift.** The `imageReference` block names a specific Canonical Ubuntu image SKU that can be renamed or superseded over time, same caveat as this repo's API-version notes elsewhere. If deployment fails on image not found, run `az vm image list --publisher Canonical --sku ubuntu --all -o table` and update the template.
- **This VM is not part of any other lab's VNet.** It gets its own `10.30.0.0/24` address space specifically so this lab stays self-contained and doesn't collide with Lab 3's `10.20.0.0/16` if a student runs both in the same subscription.

## What you learned

By completing this lab, you can now:

- Name and locate, as separate deployable resources, the four things a VM deployment actually provisions: compute (size), storage (OS disk), networking (NIC/subnet/public IP), and region.
- Explain why this lab deploys with SSH key authentication instead of a password, and connect that choice to the shared responsibility model's customer-owned OS layer.
- State the real, non-zero cost model of a VM compared to every other $0 lab in this repo, and why that distinction matters when explaining IaaS pricing.
- Identify a Standard SKU public IP vs. a (retired) Basic SKU public IP, and explain why the distinction matters for anything built today.
- Recognize an NSG rule scoped too broadly (`sourceAddressPrefix: '*'`) and describe how you'd tighten it for a real deployment.
