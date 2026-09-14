# Lab 12 — Standard Load Balancer & Azure DNS

**AZ-104 domain:** Implement and manage virtual networking (15–20%) — Configure name resolution and load balancing
**Cost:** Not literally free, but trivial for a same-day demo. **Standard Load Balancer bills a small hourly rate plus data-processed charges; a public DNS zone bills roughly $0.50/month, prorated to the day.** Both are easy to overlook as "free networking plumbing" — they aren't. Delete when done.
**Time:** ~20 minutes

## What you'll build

A public-facing **Standard SKU Load Balancer** with a backend address pool, a TCP health probe on port 80, a load-balancing rule forwarding frontend port 80 to backend port 80, and an **explicit outbound rule** — Standard SKU requires one for backend instances to reach the internet, unlike Basic SKU's implicit outbound access. Alongside it, a **public Azure DNS zone** with an A record pointing `www.<zone>` at the load balancer's public IP. This lab builds the Layer-4 traffic-distribution and name-resolution mechanics the exam tests directly, independent of whether any real backend VMs or a real registered domain exist.

## Deploy

```bash
az group create --name rg-az104-lab12 --location eastus

az deployment group create \
  --resource-group rg-az104-lab12 \
  --template-file main.bicep
```

## Verify

```bash
az network lb show --resource-group rg-az104-lab12 --name lb-az104lab12 \
  --query "{name:name, sku:sku.name}" -o json

az network lb address-pool list --resource-group rg-az104-lab12 --lb-name lb-az104lab12 -o table
az network lb probe list --resource-group rg-az104-lab12 --lb-name lb-az104lab12 -o table
az network lb rule list --resource-group rg-az104-lab12 --lb-name lb-az104lab12 -o table
az network lb outbound-rule list --resource-group rg-az104-lab12 --lb-name lb-az104lab12 -o table

az network dns zone show --resource-group rg-az104-lab12 --name az104lab12-demo.com \
  --query "{name:name, nameServers:nameServers}" -o json

az network dns record-set a list --resource-group rg-az104-lab12 --zone-name az104lab12-demo.com -o table
```

In the portal: `lb-az104lab12` → **Backend pools**, **Health probes**, and **Load balancing rules** together, then **Outbound rules** specifically, and the DNS zone's **Overview** for its auto-generated NS/SOA records plus the `www` A record.

## Manual tasks (can't be done by Bicep)

A public DNS zone only resolves on the real internet once you delegate the domain's nameservers at its registrar to the NS records Azure generated for this zone:

```bash
az network dns zone show --resource-group rg-az104-lab12 --name az104lab12-demo.com --query nameServers
```

This lab deliberately does **not** require that step — delegating a real domain means actually owning one, which is entirely optional here. The zone, its records, and the portal/CLI mechanics for managing them are fully real and fully exam-testable without ever pointing a live domain at them.

## Clean up

```bash
az group delete --name rg-az104-lab12 --yes --no-wait
```

## Lecture talking points

- **Standard Load Balancer requires explicit outbound rules (or a NAT Gateway) for internet egress.** Basic SKU gave backend instances implicit outbound access; Standard does not. This is exactly the kind of "it worked in the old tier, why doesn't it work now" trap the exam likes, and it's a direct, practical reason organizations get surprised mid-migration from Basic to Standard.
- **Health probes decide who actually gets traffic, not who's merely in the pool.** A backend instance can be a fully-valid member of the backend address pool and still receive zero traffic if the probe marks it unhealthy. "In the pool" and "receiving traffic" are two different questions.
- **Load Balancer is Layer 4 — it doesn't know what HTTP is.** It forwards TCP/UDP based on IP and port, nothing about paths, headers, or hostnames. Contrast briefly with Application Gateway (Layer 7, HTTP-aware, path-based routing) from the course outline's terminology list — worth naming the distinction in one sentence without building a second lab around it.
- **A DNS zone and its records are fully real and testable without ever delegating a domain.** The record-management mechanics — creating a zone, adding an A record, reading the auto-generated NS/SOA records — are exam content on their own. Whether a domain you own actually points at this zone is a separate, optional step that changes nothing about what's testable here.
- **Outbound rules are a distinct object from load-balancing rules**, even though both sit on the same Load Balancer resource — one governs inbound traffic distribution to the backend pool, the other governs how that same pool reaches out to the internet. Worth pointing at both blades side by side so students don't conflate them.

## What you learned

By completing this lab, you can now:

- Deploy a **Standard SKU Load Balancer** with a backend pool, health probe, and load-balancing rule wired together correctly.
- Explain why Standard SKU needs an **explicit outbound rule** where Basic SKU did not, and state the production symptom this causes when missed.
- Distinguish a health probe's role (who receives traffic) from backend pool membership (who's merely registered) when diagnosing "some instances aren't getting requests."
- Place Load Balancer correctly as a **Layer 4** service and contrast it in one sentence with Application Gateway's Layer 7, HTTP-aware routing.
- Create and manage an **Azure DNS zone and A record**, and explain what domain delegation would add on top of mechanics that are already fully real without it.
