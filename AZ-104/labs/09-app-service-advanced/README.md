# Lab 09 — App Service: Deployment Slots & VNet Integration

**AZ-104 domain:** Deploy and manage Azure compute resources (20–25%) — Create and configure Azure App Service
**Cost:** REAL and NOT cheap if left running — Standard S1 is roughly $0.10/hour, which works out to about **$70/month** if you leave it running. This is the most expensive "just sitting there" lab in the AZ-104 set after Bastion. Delete it the same day, or at minimum scale the plan down immediately after the demo.
**Time:** ~25 minutes

## What you'll build

An App Service Plan on **Standard S1** — specifically because deployment slots require Standard tier or above, which is why this lab can't reuse AZ-900 Lab 6's free F1 plan — a Web App with a **staging deployment slot**, and **regional VNet integration** wiring the app to a subnet delegated to `Microsoft.Web/serverFarms`. AZ-900 Lab 6 showed App Service as "a place to run a web app, no VM required." This lab shows what becomes possible once you're paying for a tier that unlocks admin-level features.

## Deploy

```bash
az group create --name rg-az104-lab09 --location eastus

az deployment group create \
  --resource-group rg-az104-lab09 \
  --template-file main.bicep \
  --parameters webAppName=az104lab09<your-initials>
```

> Web app names are globally unique (they become `<name>.azurewebsites.net`). If deployment fails on name conflict, add more uniqueness to `webAppName`.

## Verify

```bash
az webapp show --resource-group rg-az104-lab09 --name az104lab09<your-initials> \
  --query "{name:name, defaultHostName:defaultHostName, state:state}" -o table

az webapp deployment slot list --resource-group rg-az104-lab09 --name az104lab09<your-initials> -o table

az webapp show --resource-group rg-az104-lab09 --name az104lab09<your-initials> \
  --query "virtualNetworkSubnetId" -o tsv
```

Open both the production hostname and `<app>-staging.azurewebsites.net` in a browser — each returns the default "your app is running" placeholder page, since no code has been deployed to either. That's expected.

## Manual tasks (can't be done by Bicep)

1. **Scale the App Service plan — scale up (SKU/tier) and scale out (instance count) are two different operations, and the exam tests the distinction directly.**

   **Scale up/down** changes *what* each instance is — the SKU/tier, which controls CPU, memory, and which platform features (like deployment slots) even exist at that price point. **Scale out/in** changes *how many* identical instances exist on the same tier — more copies of the same instance, not more power per instance. Don't confuse the two: "scale up to handle more load" is a common but imprecise way people talk about this, and the exam expects you to know which lever you're actually pulling.

   **Scale up** — this is a genuinely more expensive tier, not just a bigger number, so given this lab's own cost warning above: know the command, but think twice before actually running it.
   ```bash
   az appservice plan update --resource-group rg-az104-lab09 --name asp-az104lab09 --sku P1V3
   ```
   P1V3 (Premium v3) runs meaningfully more per hour than S1. If you do run it, scale back down right after confirming it worked:
   ```bash
   az appservice plan update --resource-group rg-az104-lab09 --name asp-az104lab09 --sku S1
   ```

   **Scale out** — same S1 tier, just more instances, so the cost is linear and modest enough to actually run: going from 1 instance to 2 roughly doubles the plan's ~$0.10/hour (so ~$0.20/hour, or roughly $140/month, while it stays at 2 — scale it back down when you're done):
   ```bash
   az appservice plan update --resource-group rg-az104-lab09 --name asp-az104lab09 --number-of-workers 2
   ```
   ```bash
   az appservice plan update --resource-group rg-az104-lab09 --name asp-az104lab09 --number-of-workers 1
   ```

2. **Deploy something to staging, then swap it into production.**
   Confirming the staging slot has its own independent URL (`<app>-staging.azurewebsites.net`) is enough for this lab — you don't need to actually push custom code. When you're ready to promote it:
   ```bash
   az webapp deployment slot swap --resource-group rg-az104-lab09 \
     --name az104lab09<your-initials> --slot staging --target-slot production
   ```
   A swap exchanges the **running app instances** between slots (with Azure "warming up" the staging slot's app before the swap completes) rather than redeploying code in place — that's why it's a near-zero-downtime way to promote a tested build.

3. **Custom domain + TLS binding — genuinely manual, needs a domain you actually own.** Not required to complete this lab; described here so you know where it lives:
   - **Custom domains** blade → add your hostname → validate ownership via a TXT or CNAME record at your domain registrar → bind either an **App Service Managed Certificate** (free, auto-renewing) or your own uploaded certificate.

4. **Built-in Backup — also a portal/CLI config step, not automated here.** App Service Backup needs a storage account and a SAS URL picked in the portal (**Backups** blade → Configure → choose storage account/container). Not required to complete this lab.

## Clean up

```bash
az group delete --name rg-az104-lab09 --yes --no-wait
```

## Lecture talking points

- **Scale up vs. scale out is one of the most reliably tested distinctions in this whole domain.** Scale up/down = change the SKU/tier (more CPU/memory/features per instance). Scale out/in = change the instance count (more copies of the same instance, same tier). The portal even exposes them as two separate blades with different names — "Scale up (App Service plan)" and "Scale out (App Service plan)" — which is a strong hint the exam writers think of them as genuinely different operations, not two flavors of the same one.
- **Standard tier (or above) is a hard requirement for deployment slots — not a preference, a platform limitation, and directly testable.** F1 and the Basic tiers simply don't offer the feature at any price; it's not something you can configure your way into on a cheaper plan.
- **Slot swap vs. a fresh deploy — why swap is near-zero-downtime.** A swap exchanges running app instances (with a warm-up step) rather than redeploying code into a live slot, which is why it avoids the cold-start/brief-unavailability window a straight redeploy-to-production would have.
- **Regional VNet integration is outbound-only, and that's an easy exam trap.** It lets the app reach resources *inside* the VNet (a private database, say) — it does not make the app's own inbound traffic private. Making inbound traffic private is what a **private endpoint** on the app would add, which is a forward reference to the networking labs later in this course.
- **Direct callback to AZ-900 Lab 6.** Same service, same "no VM, no OS patching" PaaS story — but now at a tier where slots, custom domains, and VNet integration actually exist as options, because F1 never offered any of them.
- **Say the cost difference out loud before deploying.** AZ-900's App Service lab was $0 by design (F1). This one is genuinely ~$70/month if forgotten. Naming that gap is the whole discipline this repo keeps building toward.

## What you learned

By completing this lab, you can now:

- Scale an App Service plan both **up** (SKU/tier, via `--sku`) and **out** (instance count, via `--number-of-workers`), and explain the difference between the two in one sentence.
- Explain why deployment slots require Standard tier or above, and that this is a hard platform gate, not a configuration choice.
- Perform (or describe precisely) a deployment slot swap, and explain why it's near-zero-downtime compared to a fresh deploy.
- Configure regional VNet integration on a Web App and state exactly what it does and doesn't make private.
- Describe, conceptually, the manual steps for binding a custom domain + managed certificate and for configuring built-in Backup — without needing to own a domain to understand them.
- State the real monthly cost of a Standard S1 plan left running, and connect that to why prompt cleanup matters more on this lab than on most others in this course.
