# Lab 10 — VNet Peering & User-Defined Routes

**AZ-104 domain:** Implement and manage virtual networking (15–20%) — Configure and manage virtual networks in Azure
**Cost:** $0 for the VNets, peering, and route table. The Standard public IP has a small real hourly charge even with nothing attached to it (a few cents/day) — not free, just cheap. Basic SKU public IPs are being retired by Microsoft, so Standard isn't a cost-saving alternative here, it's the only sensible default.
**Time:** ~20 minutes

## What you'll build

A **hub** VNet (`10.0.0.0/16`) and a **spoke** VNet (`10.1.0.0/16`), each with one workload subnet, connected by **bidirectional VNet peering** — two separate peering resources, one per VNet. The spoke's subnet carries a **route table** with a user-defined route (UDR) sending all outbound traffic (`0.0.0.0/0`) to a demo "virtual appliance" next hop. A standalone Standard public IP rounds out the lab. AZ-900 Lab 3 taught a single VNet with NSG-segmented subnets; this lab goes one level up the topology — two VNets connected to each other, with routing control over what happens to traffic between them.

## Deploy

```bash
az group create --name rg-az104-lab10 --location eastus

az deployment group create \
  --resource-group rg-az104-lab10 \
  --template-file main.bicep
```

## Verify

```bash
az network vnet peering list --resource-group rg-az104-lab10 --vnet-name vnet-az104lab10-hub -o table
az network vnet peering list --resource-group rg-az104-lab10 --vnet-name vnet-az104lab10-spoke -o table

az network route-table route list \
  --resource-group rg-az104-lab10 \
  --route-table-name rt-az104lab10-spoke -o table

az network public-ip show \
  --resource-group rg-az104-lab10 --name pip-az104lab10 \
  --query "{name:name, sku:sku.name, allocation:publicIPAllocationMethod, zones:zones}" -o json
```

In the portal: each VNet's **Peerings** blade to confirm both sides show `Connected`, and `rt-az104lab10-spoke`'s **Subnets** blade to confirm the route table is actually associated to `snet-spoke-workload` — a route table that isn't associated to anything does nothing.

## Clean up

```bash
az group delete --name rg-az104-lab10 --yes --no-wait
```

Everything in this lab lives in one resource group, so a single delete removes both VNets, both peering objects, the route table, and the public IP together.

## Lecture talking points

- **Peering is two resources, not one.** Bicep (and Resource Manager generally) has no single "peering pair" object — each VNet gets its own `virtualNetworkPeerings` child resource pointing at the other. Contrast this directly with the portal's "+ Add peering" wizard, which creates both sides for you in one click and can make students think peering is a single object. The walkthrough for this lab shows that contrast live.
- **`allowGatewayTransit` and `useRemoteGateways` only matter once a real gateway exists.** `allowGatewayTransit` is set on the VNet that *has* (or would have) a VPN/ExpressRoute gateway, offering it to the peer. `useRemoteGateways` is set on the side that wants to *consume* that gateway. This lab sets both to `false` because no gateway is deployed — but the exam tests the mechanism, not whether your lab budget stretched to a real gateway, so know what each flag does even without ever flipping it to `true`.
- **A UDR's `VirtualAppliance` next hop is not validated by Azure.** You can point a route at any private IP you like, including one nothing is listening on — Azure routes traffic there regardless. This is exactly why a typo'd or stale UDR can silently black-hole production traffic: the configuration looks completely correct until someone tries to actually use the path.
- **A route table that exists but isn't associated to a subnet is inert.** Creating `rt-az104lab10-spoke` doesn't route anything by itself — only the subnet's `routeTable` association (set on `snet-spoke-workload` here) turns it on. Worth checking live in the Subnets blade, not just trusting the route table's own Routes list.
- **Standard vs. Basic public IP SKUs — Basic is being retired.** Standard is zone-redundant by default and secure-by-default (it requires an NSG on whatever it's attached to; Basic does not). This lab's public IP sits unattached just to inspect its properties — later labs attach this same SKU to a Bastion host and a Load Balancer.
- **Direct callback to AZ-900 Lab 3.** That lab segmented one VNet into subnets with NSGs. This lab connects two separate VNets to each other and adds routing control over the traffic crossing that connection — the natural next step once a real environment has more than one VNet.

## What you learned

By completing this lab, you can now:

- Deploy **VNet peering** correctly as two independent resources, one per VNet, each referencing the other.
- Explain `allowGatewayTransit` and `useRemoteGateways` conceptually, including which side of a hub-spoke pair sets which flag, even without a gateway present to test it against.
- Write a **user-defined route** with a `VirtualAppliance` next hop, and explain why Azure does not validate that anything is listening at the target IP.
- Associate a route table to a subnet, and recognize that an unassociated route table has no effect regardless of what routes it contains.
- Explain why Standard SKU public IPs are now the only sensible default, given Basic SKU's retirement, independent of any cost-saving argument.
