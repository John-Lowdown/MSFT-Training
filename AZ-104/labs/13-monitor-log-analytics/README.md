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

3. **VM Insights — a distinct, named Azure Monitor feature, not just "another metric."** VM Insights installs the Azure Monitor Agent (AMA) plus a purpose-built Data Collection Rule (DCR) on a VM, and gives you a dedicated Insights view — performance charts and a live dependency map — that goes well beyond a generic platform metric or alert. It needs an existing VM as a target, which this lab doesn't deploy itself; reuse Lab 06's `vm-az104lab06` if it's still around.

   **Portal path (primary — genuinely simpler than hand-rolling this via CLI):** open the VM → **Insights** (under **Monitoring**) → **Enable**. The portal handles installing the AMA extension and associating the built-in "VM Insights" DCR for you — you don't pick individual performance counters by hand.

   A CLI/ARM path exists too (installing the `AzureMonitorLinuxAgent`/`AzureMonitorWindowsAgent` extension via `az vm extension set`, then creating and associating a Data Collection Rule that targets the VM Insights DCR template via `az monitor data-collection rule create` / `az monitor data-collection rule association create`) — it's a legitimate way to do this at scale or in a pipeline, but it's meaningfully more involved than the one-click portal path for a single demo VM, which is why the portal path is the one to actually use here.

   However you enable it, **give it several minutes** before expecting to see data — the map view and performance charts populate only after the agent has been running and reporting for a short while, not instantly on enable.

4. **Connection Monitor (Network Watcher) — proactive, ongoing connectivity testing, genuinely different from a flow log.** A flow log passively records traffic that already happened. Connection Monitor actively and repeatedly tests connectivity between two endpoints — a VM to another VM, or a VM to an external endpoint like a well-known IP or URL — and reports latency/reachability over time. The destination doesn't need to be anything complex for demo purposes; a public DNS IP or a well-known URL is fine.

   Portal path: **Network Watcher → Connection Monitor → + Create** → pick a source VM (e.g. `vm-az104lab06`) and a destination (another VM, or an external endpoint) → create.

   CLI equivalent:
   ```bash
   az network watcher connection-monitor create \
     --name cm-az104lab13-demo \
     --location eastus \
     --endpoint-source-name vm-az104lab06 \
     --endpoint-source-resource-id <vm-resource-id> \
     --endpoint-dest-name external-endpoint \
     --endpoint-dest-address www.microsoft.com \
     --test-config-name tcp-default \
     --protocol Tcp \
     --test-frequency 30
   ```

   Results take a few minutes to start populating once the monitor is created. **Connection Monitor tests are ongoing and recurring** (running on the configured test frequency indefinitely, not a one-shot check) — that ongoing nature is specifically what distinguishes it from a simpler one-time connectivity check like `az network watcher test-connectivity` or `az vm boot-diagnostics`. Delete it when you're done looking at it:

   ```bash
   az network watcher connection-monitor delete --location eastus --name cm-az104lab13-demo
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

**If you enabled VM Insights, this does NOT clean it up either.** VM Insights installs an agent extension and associates a Data Collection Rule *on the VM itself*, which almost certainly lives in a different resource group (Lab 06's, if you reused that VM) — deleting `rg-az104-lab13` never touches it. If you want to fully remove it, disable it from the VM's **Insights** blade (or remove the DCR association and uninstall the AMA extension), or simply leave it — the agent itself carries no meaningful ongoing cost, though it does keep sending data to the Log Analytics workspace this lab deployed, which you're deleting.

**If you created a Connection Monitor, it also lives outside `rg-az104-lab13` (under Network Watcher) and won't be removed by this delete.** Remove it separately:

```bash
az network watcher connection-monitor delete --location eastus --name cm-az104lab13-demo
```

## Lecture talking points

- **Metrics and logs are genuinely different Azure Monitor data types, tested as a pair.** Metrics are numeric, time-series, lightweight, and good for alerting — that's the entirety of AZ-900 Lab 7. Logs are structured records, queryable with KQL, richer in detail, and not free to ingest. This lab is the first time both halves sit in the same deployment so the contrast is concrete rather than a comparison-table abstraction.
- **A diagnostic setting is the plumbing, and without one, most resource logs simply vanish.** A storage account (or almost any Azure resource) doesn't retain its own detailed logs anywhere by default. A diagnostic setting is what routes them somewhere durable — a Log Analytics workspace, a storage account, or an Event Hub. No diagnostic setting, no logs to query, full stop.
- **Why this lab needed two diagnostic settings, not one.** Account-level metrics and blob-service-level logs are scoped to different resources in the ARM hierarchy — the metric setting scopes to the storage account itself, the log setting scopes to the blob service sub-resource underneath it. Students who only look at the storage account's own Diagnostic settings blade may miss that the blob-service one exists at all.
- **Simple mode vs. full KQL mode is worth demoing live, not just describing.** The portal's Logs blade simple mode is a checkbox/dropdown UI that is *secretly writing the same KQL* you'd type by hand — toggling to see the generated query (where the portal still offers it) is one of the more convincing "oh, that's what this is" moments in the whole monitoring domain.
- **VM Insights is a distinct, named Azure Monitor feature — deeper than the metric alert built earlier in this lab.** The `transactionsAlert` resource in this lab's Bicep watches one metric (`Transactions`) and fires past a threshold — useful, but shallow. VM Insights is a purpose-built view: it installs the Azure Monitor Agent plus a dedicated Data Collection Rule to give you performance charts *and* a live dependency map showing what a VM talks to. Both are "Azure Monitor," but they're not the same depth of monitoring, and the exam names VM Insights specifically rather than treating it as just another metric.
- **Connection Monitor and flow logs are both "watch the network," but they solve different problems — and this lab now touches both.** A flow log is passive: it records traffic that already happened, after the fact. Connection Monitor is active and ongoing: it proactively and repeatedly tests connectivity between two endpoints on a schedule, reporting latency and reachability over time, whether or not any real traffic happened to flow. Knowing which one to reach for — "what already happened on this NSG" vs. "is this path currently healthy" — is a genuinely distinct exam and practical-skills question.
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
- Enable **VM Insights** on a VM (via the portal's one-click path, and describe the more involved AMA + Data Collection Rule CLI equivalent) and explain what it gives you beyond a generic metric.
- Create a **Connection Monitor** test between two endpoints and explain why its ongoing, recurring nature is what distinguishes it from a flow log's passive traffic recording and from a one-shot connectivity check.
