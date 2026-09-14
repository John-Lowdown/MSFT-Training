# Lab 13 — Log Analytics, Diagnostic Settings & KQL

**AZ-104 domain:** Monitor and maintain Azure resources (10–15%) — Monitor resources in Azure
**Cost:** near-$0 — an empty storage account, a low-volume Log Analytics workspace, a free action group, and a platform metric alert. Log Analytics ingestion is billed per GB, but a new workspace like this one typically stays within Azure's free daily data allotment for a short demo. The one part of this lab that can meaningfully add cost if left running is the optional flow-log manual task — see below.
**Time:** ~25 minutes

## What you'll build

A **Log Analytics workspace**, a storage account wired to it through two **diagnostic settings** — one shipping account-level **metrics** (`Transaction`), one shipping blob-service **logs** (`allLogs`) — and a **metric alert** on transaction count wired to an **action group**. AZ-900 Lab 7 covered only the metrics-and-alerting half of Azure Monitor; this lab adds the logs-and-query half so you see both halves of "Monitor resources in Azure" side by side, in one deployment, instead of as two disconnected exam bullet points.

## Deploy

```bash
az group create --name rg-az104-lab13 --location eastus

az deployment group create \
  --resource-group rg-az104-lab13 \
  --template-file main.bicep \
  --parameters contactEmail=you@example.com
```

## Verify

```bash
az monitor log-analytics workspace show \
  --resource-group rg-az104-lab13 --workspace-name law-az104lab13 \
  --query "{name:name, retentionInDays:retentionInDays, sku:sku.name}" -o table

STORAGE_ID=$(az deployment group show --resource-group rg-az104-lab13 --name main \
  --query "properties.outputs.storageAccountId.value" -o tsv)

az monitor diagnostic-settings list --resource $STORAGE_ID -o table

az monitor metrics alert show \
  --name alert-az104lab13-transactions \
  --resource-group rg-az104-lab13 \
  --query "{name:name, enabled:enabled, severity:severity}" -o json
```

In the portal: **rg-az104-lab13 → the storage account → Diagnostic settings** to confirm both settings and their destinations, and **law-az104lab13 → Logs** to run queries against what they're shipping.

## Manual tasks (can't be done by Bicep)

1. **Run a KQL query against what this lab actually ingests.** The diagnostic settings above enable the `Transaction` metric category and the `allLogs` log category group on blob storage, so two queries are genuinely runnable here — pick whichever matches the data you want to look at:

   Blob request logs (populates `StorageBlobLogs`):
   ```kusto
   StorageBlobLogs
   | summarize count() by OperationName
   ```

   Account metrics shipped to the workspace (populates `AzureMetrics`):
   ```kusto
   AzureMetrics
   | where ResourceProvider == "MICROSOFT.STORAGE"
   | summarize avg(Average) by bin(TimeGenerated, 1h)
   ```

   Open **law-az104lab13 → Logs**. The query box defaults to **simple mode** — a filter/column picker UI appropriate for quick exploration — with a **KQL mode** toggle that switches to the full query language shown above. If your portal still offers it, use the "show query" affordance in simple mode before switching: it reveals that simple mode was generating the exact same KQL underneath the whole time, just without you typing it. If `StorageBlobLogs` or `AzureMetrics` come back empty, give it 10-15 minutes — diagnostic data takes a short while to start flowing after the settings are created, and you may need to generate some blob activity (even a failed `az storage blob list` against the account) for the logs table specifically.

2. **Enabling a flow log is a manual task on purpose, not a Bicep gap.** `Microsoft.Network/networkWatchers/flowLogs` is a real, Bicep-authorable resource type — but it's deliberately left out of `main.bicep` because it has to attach to a **Network Watcher instance**, and Network Watcher instances are normally auto-created by Azure per region (named `NetworkWatcher_<region>`, e.g. `NetworkWatcher_eastus`) rather than something you'd author yourself in a template. This lab has no VNet/NSG of its own to attach a flow log to anyway, so treat this as an optional, standalone demo against any NSG you already have (e.g. from Lab 06):

   ```bash
   az network watcher flow-log create \
     --location eastus \
     --nsg <your-nsg-name> \
     --name fl-az104lab13-demo \
     --resource-group NetworkWatcherRG \
     --workspace <law-az104lab13-resource-id> \
     --enabled true
   ```

   **Flow logs and their optional Traffic Analytics add-on are genuinely billed for as long as they're enabled** — this is real, ongoing cost, unlike everything else in this lab. Treat it as optional and demo-only, and disable it immediately after you've looked at it:

   ```bash
   az network watcher flow-log delete --location eastus --name fl-az104lab13-demo --resource-group NetworkWatcherRG
   ```

## Clean up

```bash
az group delete --name rg-az104-lab13 --yes --no-wait
```

Both diagnostic settings and the metric alert are children of resources inside `rg-az104-lab13`, so they're removed along with everything else in one delete.

**If you did the optional flow-log manual task, this does NOT clean it up.** Flow logs attach to a Network Watcher instance, which almost always lives in a *different*, auto-created resource group (typically `NetworkWatcherRG`) — not in `rg-az104-lab13`. Deleting this lab's resource group leaves that flow log (and its ongoing billing) running untouched. Remove it separately:

```bash
az network watcher flow-log delete --location eastus --name fl-az104lab13-demo --resource-group NetworkWatcherRG
```

## Lecture talking points

- **Metrics and logs are genuinely different Azure Monitor data types, tested as a pair.** Metrics are numeric, time-series, lightweight, and good for alerting — that's the entirety of AZ-900 Lab 7. Logs are structured records, queryable with KQL, richer in detail, and not free to ingest. This lab is the first time both halves sit in the same deployment so the contrast is concrete rather than a comparison-table abstraction.
- **A diagnostic setting is the plumbing, and without one, most resource logs simply vanish.** A storage account (or almost any Azure resource) doesn't retain its own detailed logs anywhere by default. A diagnostic setting is what routes them somewhere durable — a Log Analytics workspace, a storage account, or an Event Hub. No diagnostic setting, no logs to query, full stop.
- **Why this lab needed two diagnostic settings, not one.** Account-level metrics and blob-service-level logs are scoped to different resources in the ARM hierarchy — the metric setting scopes to the storage account itself, the log setting scopes to the blob service sub-resource underneath it. Students who only look at the storage account's own Diagnostic settings blade may miss that the blob-service one exists at all.
- **Simple mode vs. full KQL mode is worth demoing live, not just describing.** The portal's Logs blade simple mode is a checkbox/dropdown UI that is *secretly writing the same KQL* you'd type by hand — toggling to see the generated query (where the portal still offers it) is one of the more convincing "oh, that's what this is" moments in the whole monitoring domain.
- **Network Watcher is a different kind of resource than everything else in this lab.** Every other resource here — the workspace, the storage account, the diagnostic settings, the alert — is something you explicitly authored in Bicep. Network Watcher is normally per-region and Azure-managed, auto-appearing the first time something in a region needs it. Knowing that distinction (author-it-yourself vs. Azure-manages-it-for-you) is a small but real exam and practical-skills point.
- **Direct callback to AZ-900 Lab 7.** Same metric-alert-plus-action-group shape, same storage account target — this lab deliberately keeps that half nearly identical so all the new teaching weight lands on the logs/KQL side.

## What you learned

By completing this lab, you can now:

- Create a **Log Analytics workspace** and explain what its pricing tier and retention setting actually control.
- Wire a resource to a workspace with a **diagnostic setting**, and explain why metrics and logs from the same storage account may need separate diagnostic settings scoped to different sub-resources.
- Write and run a basic **KQL** query against both a logs table (`StorageBlobLogs`) and a metrics table (`AzureMetrics`) in the Logs blade.
- Explain the relationship between the portal's **simple query mode** and full KQL — and where to find the toggle that proves simple mode is generating KQL underneath.
- Recognize why **Network Watcher / flow logs** were deliberately left as a manual task rather than a Bicep resource, and the ongoing cost implication of leaving a flow log enabled.
- Distinguish Azure Monitor's **metrics** and **logs** as two separate, commonly paired exam concepts rather than one undifferentiated "monitoring" bucket.
