# Lab 3 — Virtual Network & NSGs

**AZ-900 domain:** Core Services — Networking
**Cost:** $0 (VNets and NSGs carry no charge on their own)
**Time:** ~15 minutes

## What you'll build
One VNet (`10.20.0.0/16`) with two subnets — `snet-web` and `snet-data` — each with its own Network Security Group. The web NSG allows inbound HTTPS from the internet; the data NSG allows inbound SQL (1433) **only from the web subnet**, and nothing from the internet at all. This is the classic two-tier segmentation pattern.

## Deploy

```bash
az group create --name rg-az900-lab03 --location eastus

az deployment group create \
  --resource-group rg-az900-lab03 \
  --template-file main.bicep
```

## Verify

```bash
az network vnet subnet list --resource-group rg-az900-lab03 --vnet-name vnet-az900-lab03 -o table
az network nsg rule list --resource-group rg-az900-lab03 --nsg-name nsg-az900-lab03-data -o table
```

In the portal: open `nsg-az900-lab03-data` → **Inbound security rules** and point out there's no "Allow from Internet" rule — only the default deny-all and the one rule scoped to the web subnet's address range.

## Clean up

```bash
az group delete --name rg-az900-lab03 --yes --no-wait
```

## Lecture talking points

- **NSGs are stateful and evaluated by priority, lowest number first, first match wins.** Every NSG also has default rules students didn't write (`AllowVnetInBound`, `AllowAzureLoadBalancerInBound`, `DenyAllInBound`, and the outbound equivalents) — show these in the portal since they're invisible in the Bicep file and are a common source of "why is this ports appears open/closed when I didn't configure it" confusion.
- **NSGs can attach to a subnet, a NIC, or both** — this lab attaches at the subnet level (simpler to reason about, and what AZ-900 emphasizes), but call out that NIC-level NSGs exist and rules from both apply.
- **This is defense in depth in miniature**, not a substitute for identity or encryption: an NSG controls *reachability at the network layer* — it says nothing about whether a request that gets through is authenticated.
- **VNets don't cost anything** — a good moment to contrast with on-prem networking, where standing up equivalent segmentation means physical VLANs and hardware firewalls. This is a clean example for Module 2 (cloud concepts — CapEx vs OpEx).
- Segue to Lab 6 (App Service): PaaS services like App Service don't sit inside your VNet by default — VNet integration is an explicit, extra step. Worth flagging now so it isn't a surprise later.

## What you learned

By completing this lab, you can now:

- Explain how NSG rules are evaluated (priority number, lowest first, first match wins) and name the default rules Azure adds automatically that students never wrote themselves.
- Describe where an NSG can attach — a subnet, a NIC, or both — and why this lab attaches at the subnet level.
- State that an NSG controls network-layer reachability only, and place it correctly within defense in depth as one layer among several, not a substitute for identity or encryption.
- Explain why VNets and NSGs carry no charge, and contrast that with the cost of building equivalent segmentation on-premises (VLANs, physical firewalls).
- Explain why a PaaS service like App Service doesn't sit inside a VNet by default, setting up the contrast Lab 6 makes concrete.
