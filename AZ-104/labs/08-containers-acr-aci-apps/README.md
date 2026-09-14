# Lab 08 — Containers: Registry, Container Instances & Container Apps

**AZ-104 domain:** Deploy and manage Azure compute resources (20–25%) — Provision and manage containers
**Cost:** Near-$0 if deleted promptly. ACR Basic bills a flat ~$0.167/day. ACI bills per-second while running — trivial for a short demo, but **it runs continuously until you stop it, unlike the Container App, which scales to zero.** Container Apps Consumption genuinely costs ~$0 once idle traffic stops. Delete within the hour, especially the Container Instance.
**Time:** ~25 minutes

## What you'll build

Three distinct "run a container" services, side by side, so the differences between them stop being a memorization exercise: an **Azure Container Registry** (Basic SKU — stores images, doesn't run anything), an **Azure Container Instance** running a small public test image with `restartPolicy: Never`, and an **Azure Container App** on the Consumption plan with `minReplicas: 0` (scale-to-zero).

## Deploy

```bash
az group create --name rg-az104-lab08 --location eastus

az deployment group create \
  --resource-group rg-az104-lab08 \
  --template-file main.bicep
```

## Verify

```bash
az acr show --resource-group rg-az104-lab08 --name $(az deployment group show --resource-group rg-az104-lab08 --name main --query "properties.outputs.acrName.value" -o tsv) -o table

az container show --resource-group rg-az104-lab08 --name aci-az104lab08 \
  --query "{state:instanceView.state, fqdn:ipAddress.fqdn}" -o table

az containerapp show --resource-group rg-az104-lab08 --name ca-az104lab08 \
  --query "{fqdn:properties.configuration.ingress.fqdn, minReplicas:properties.template.scale.minReplicas}" -o table
```

Open the ACI's FQDN and the Container App's FQDN in a browser — both should return a simple "hello world" style page. In the portal: **rg-az104-lab08** to see all three compute-adjacent resources (registry, container group, container app + its managed environment) together.

## Manual tasks (can't be done by Bicep)

1. **Build and push a custom image straight to the registry, no local Docker needed.**
   ```bash
   mkdir acr-build-demo && cd acr-build-demo
   echo "FROM mcr.microsoft.com/azuredocs/aci-helloworld" > Dockerfile
   ACR_NAME=$(az deployment group show --resource-group rg-az104-lab08 --name main --query "properties.outputs.acrName.value" -o tsv)
   az acr build --registry $ACR_NAME --image demo:v1 .
   ```
   `az acr build` uploads your build context and runs the build **in Azure** — no Docker Engine required on your machine. A one-line placeholder Dockerfile (just a `FROM`) is enough for this lab.

2. **Geo-replication is a Premium-only, real-money feature — be aware of it, don't provision it here.** The portal/CLI step looks like:
   ```bash
   az acr replication create --registry <name> --location westus
   ```
   This requires upgrading the registry to **Premium** first, and a Premium registry plus each additional replica location bills continuously, region by region, for as long as they exist. Know the command and the Premium requirement for the exam — **do not actually run this in the lab.**

## Clean up

```bash
az group delete --no-wait --name rg-az104-lab08 --yes
```

All three resource types (and the Log Analytics workspace backing the Container Apps environment) delete together. The Container Apps **managed environment** in particular can take a few extra minutes to finish deleting in the background after the resource group delete returns — that's expected, not a hang.

## Lecture talking points

- **Three genuinely different container compute models, tested separately.** ACR is just a registry — it stores images and runs nothing. ACI runs one container group with no orchestration and bills continuously while running. Container Apps runs on Kubernetes under the hood but abstracts it away entirely, supporting scale-to-zero and HTTP-based autoscale — the more "PaaS-like" modern option of the three. The exam expects you to place a given scenario into the right one of these three buckets.
- **Restart policy is a cost lever, not just a reliability setting.** `Never` (this lab) vs. `OnFailure` vs. `Always` — picking `Always` on a container that crash-loops means you're billed for continuous restarts. Know all three values and what each means for cost and availability.
- **Premium ACR SKU is required for geo-replication — a specific, testable fact.** Basic and Standard don't offer it at any price; it's not a "pay more on the same tier" feature, it's a hard tier gate.
- **Scale-to-zero is the real cost differentiator in this lab.** The Container App can legitimately cost nothing once idle; the Container Instance cannot — it runs until explicitly stopped or deleted. That asymmetry is worth saying out loud before anyone leaves this lab running overnight.
- **Direct callback to AZ-900 Lab 6 (App Service).** Another way to run code without managing VMs — but App Service runs your code directly, while this lab's three services are specifically about running it *inside containers*, which is its own exam-tested distinction.

## What you learned

By completing this lab, you can now:

- Distinguish Azure Container Registry, Azure Container Instances, and Azure Container Apps by what each one actually does, not just its name.
- Explain why ACI's `restartPolicy` affects cost, and pick the right value for a given workload.
- State that Premium is the minimum ACR tier required for geo-replication.
- Build and push a container image to ACR with `az acr build`, without needing Docker installed locally.
- Explain scale-to-zero on Container Apps and why it produces a genuinely different cost profile than a continuously-running Container Instance.
