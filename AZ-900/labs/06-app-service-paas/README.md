# Lab 6 — App Service (PaaS)

**AZ-900 domain:** Cloud Concepts — IaaS / PaaS / SaaS
**Cost:** $0 on the default F1 (Free) tier
**Time:** ~10 minutes

## What you'll build
A Linux App Service Plan (F1/Free) and a Web App running on it — enough to click through to a live default landing page and to *point at what you did not have to configure* compared to standing up a VM yourself.

## Deploy

```bash
az group create --name rg-az900-lab06 --location eastus

az deployment group create \
  --resource-group rg-az900-lab06 \
  --template-file main.bicep \
  --parameters webAppName=az900lab06<your-initials>
```

> Web app names are globally unique (they become `<name>.azurewebsites.net`). If deployment fails on name conflict, add more uniqueness to `webAppName`.

## Verify

```bash
az webapp show --name az900lab06<your-initials> --resource-group rg-az900-lab06 --query defaultHostName -o tsv
```

Open the returned hostname in a browser — you'll get the default "your app is running" placeholder page, since no code has been deployed. That's expected and enough for this lab's purpose.

## Clean up

```bash
az group delete --name rg-az900-lab06 --yes --no-wait
```

## Lecture talking points

- **This is the whole point of PaaS, made visible:** no VM to patch, no OS to choose at the infrastructure layer, no load balancer to wire up by hand — you asked for "a place to run a web app" and that's what you got. Contrast explicitly with what Lab 3's VNet would look like if you were running this same app on an IaaS VM: NSG rules, a public IP, patching cadence, a load balancer for scale.
- **The App Service Plan is the unit of billing and scale; the Web App is just code running on it.** Multiple web apps can share one plan for free (up to the plan's capacity) — a detail students often miss and that clarifies a lot of App Service pricing questions.
- **F1 (Free) has real limits worth naming**: no custom domains, no "Always On" (the app unloads after idle and cold-starts on the next request), 60 CPU-minutes/day. This lab defaults to F1 specifically so it's free, but say out loud why a real workload would move to B1 or higher — good bridge into Module 6 (pricing tiers as a lever, not just a cost line).
- **`linuxFxVersion` and the managed runtime stack** — this is the crux of PaaS: Azure manages the underlying OS and language runtime patching. Compare to "SaaS" (you manage nothing, e.g., Microsoft 365) and "IaaS" (you manage almost everything, e.g., a raw VM) to complete the IaaS/PaaS/SaaS triad this lab exists to teach.
- **`httpsOnly: true`** is set explicitly — a one-line, no-extra-cost callback to the shared responsibility model (Module 2) and security fundamentals (Module 5).
