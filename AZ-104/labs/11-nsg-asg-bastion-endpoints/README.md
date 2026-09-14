# Lab 11 — NSGs, Application Security Groups, Bastion & Private Endpoints

**AZ-104 domain:** Implement and manage virtual networking (15–20%) — Configure secure access to virtual networks
**Cost:** **Azure Bastion Standard tier costs roughly $0.19/hour — about $140 if accidentally left running for a month.** This is the single most expensive resource in the entire AZ-104 lab set. Delete it within the hour you deploy it, every time. Everything else in this lab (VNet, NSG, ASGs, private endpoint, private DNS zone, the storage account at this scale) is $0 or near-$0.
**Time:** ~30 minutes

## What you'll build

A VNet with a workload subnet and a dedicated `AzureBastionSubnet`, two **Application Security Groups** (`asg-web`, `asg-db`), an **NSG** whose one custom rule targets an ASG as its *destination* instead of a plain IP or CIDR, an **Azure Bastion** host (Standard tier) for browser-based VM access with no public IP on the VM itself, and a **private endpoint** into a storage account's blob service — backed by a **private DNS zone** so `<account>.blob.core.windows.net` actually resolves to the endpoint's private IP. AZ-900 Lab 3 taught subnet-scoped NSGs with IP-based rules; this lab replaces the IP-based source/destination with role-based ASGs and adds the two most commonly tested secure-access patterns on the exam: Bastion and private endpoints.

## Deploy

```bash
az group create --name rg-az104-lab11 --location eastus

az deployment group create \
  --resource-group rg-az104-lab11 \
  --template-file main.bicep
```

## Verify

```bash
az network nsg rule list --resource-group rg-az104-lab11 --nsg-name nsg-az104lab11 -o table

az network bastion show --resource-group rg-az104-lab11 --name bas-az104lab11 \
  --query "{name:name, sku:sku.name, provisioningState:provisioningState}" -o json

az network private-endpoint show --resource-group rg-az104-lab11 --name pe-az104lab11-blob \
  --query "{name:name, privateIp:customDnsConfigs[0].ipAddresses[0]}" -o json

az network private-dns record-set a list \
  --resource-group rg-az104-lab11 \
  --zone-name privatelink.blob.core.windows.net -o table
```

In the portal: `nsg-az104lab11` → **Inbound security rules** to see the ASG listed as a destination, and the storage account → **Networking → Private endpoint connections** to see the approved connection and its private IP.

## Manual tasks (can't be done by Bicep)

1. **View a NIC's Effective security rules.** This is a read-only inspection step, not something Bicep deploys. This lab doesn't include a VM by default (to avoid adding another billable resource just for this check) — if you happen to have a VM from an earlier lab sitting in *this same VNet* (for example, if you redeployed Lab 06's VM into `vnet-az104lab11` for practice), point this at its NIC instead of spinning up a new one just to see it.
   - **Portal:** open the VM → **Networking** → the NIC's name → **Effective security rules**.
   - **CLI:** `az network nic list-effective-nsg --name <nic-name> --resource-group rg-az104-lab11`
   - Either way, you'll see your custom rule merged with Azure's own default rules (`AllowVnetInBound`, `AllowAzureLoadBalancerInBound`, `DenyAllInBound`, and their outbound equivalents) that nobody wrote but everyone is tested on.

## Clean up

Delete Bastion and its public IP **first, explicitly** — don't just rely on `az group delete` and assume it's fast. Bastion deletion alone can take up to ~10 minutes; doing it as its own step lets you confirm it's actually gone instead of wondering why the resource group delete is hanging.

```bash
az network bastion delete --name bas-az104lab11 --resource-group rg-az104-lab11
az network public-ip delete --name pip-az104lab11-bastion --resource-group rg-az104-lab11

az group delete --name rg-az104-lab11 --yes --no-wait
```

Be patient with the first command — it's synchronous by default, so the prompt won't return until Bastion is actually gone.

## Lecture talking points

- **An NSG rule's destination (or source) can be an ASG instead of an IP or CIDR.** This lets you write rules about *roles* ("anything tagged as web tier") instead of specific addresses that change every time a VM is rebuilt or scaled. Students coming from AZ-900 Lab 3 saw subnet-prefix-based rules only — this is the same rule shape with the address swapped for a group membership.
- **Effective security rules merge your custom rules with Azure's own defaults.** `AllowVnetInBound`, `AllowAzureLoadBalancerInBound`, `DenyAllInBound`, and their outbound equivalents exist on every NSG whether you wrote them or not — they're invisible in a Bicep file (nobody declares them) and are a frequent source of "why is this port open/closed when I didn't configure it."
- **Azure Bastion removes the need for a public IP on the VM itself.** Browser-based RDP/SSH through Bastion is the direct, modern contrast to AZ-900-level "just open an NSG rule for RDP from the internet" — which is exactly the outdated-but-still-tested wrong answer on this exam. Worth saying explicitly: if a question's right answer is "don't expose RDP/SSH publicly," Bastion is very often the mechanism being tested for.
- **Private endpoint vs. service endpoint — a frequently confused exam pair.** A private endpoint gives the PaaS resource its own network interface and private IP *inside your VNet*. A service endpoint (course outline content, not built in this lab) only optimizes the *route* to a PaaS resource that remains publicly addressable — it never puts the resource's own NIC in your VNet. Students who can't state this distinction crisply are the ones who get this pair wrong on the exam.
- **The private DNS zone plus auto-registration is what makes the name actually resolve.** Without it, the private endpoint still works — it has a real private IP — but nothing automatically finds it by name, and `<account>.blob.core.windows.net` keeps resolving to the public endpoint from anywhere that doesn't have a manual DNS override. The zone group tying the endpoint to the zone is the piece that writes the matching A record for you.
- **Bastion Standard vs. Basic tier.** Basic tier exists and is the cheaper option, but Standard unlocks native-client support, IP-based connection, shareable links, and higher scale units — worth knowing both tiers exist and what separates them, even though this lab always deploys Standard.

## What you learned

By completing this lab, you can now:

- Write an NSG rule whose source or destination is an **Application Security Group** instead of an IP/CIDR, and explain why that's more durable as VMs come and go.
- Read a NIC's **Effective security rules** (portal or CLI) and distinguish your own custom rules from Azure's unwritten defaults.
- Explain what **Azure Bastion** removes from the threat model (a public IP on the VM) and contrast it with the AZ-900-level "open an NSG rule for RDP" anti-pattern.
- Deploy a **private endpoint** targeting a specific PaaS sub-resource (here, blob) and correctly distinguish it from a service endpoint.
- Wire a **private DNS zone**, its VNet link, and a private endpoint's **DNS zone group** together, and explain which piece actually creates the resolvable A record.
- Delete Azure Bastion deliberately as its own first cleanup step, rather than assuming a resource-group delete handles an expensive resource quickly.
