# Walkthrough — Log Analytics, Diagnostic Settings & KQL (Lab 13)

A guided, portal-first walkthrough of what [Lab 13](../../labs/13-monitor-log-analytics/) deploys. The lab README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for actually running a query and reading the diagnostic plumbing in the portal, so "metrics vs. logs" stops being a comparison table and becomes two tables you've queried yourself.

**Prerequisite:** Lab 13 is already deployed (`az deployment group create ...` from the lab README) and you have the resource group open in the [Azure Portal](https://portal.azure.com).

## Part 1 — Confirm the diagnostic settings

1. Open your resource group (`rg-az104-lab13`) and click into the storage account inside it.
2. In the left-hand menu, under **Monitoring**, select **Diagnostic settings**.
3. You'll see `diag-az104lab13-metrics` — open it and confirm it's sending the `Transaction` metric category to `law-az104lab13`.
4. Back on the storage account, go to **Data storage → Containers**... actually, the blob-scoped setting isn't listed on this page. Instead, from the storage account's **Diagnostic settings** blade, use the resource-type dropdown near the top (or navigate via **Monitoring → Diagnostic settings** directly on the **Blob service** sub-resource if your portal layout exposes it separately) to find `diag-az104lab13-blob-logs` and confirm it's sending the `allLogs` category group to the same workspace.

This split — one setting scoped to the account, one scoped to the blob service underneath it — is worth pointing at directly: metrics and logs for the "same" storage account aren't always configured from the same blade.

## Part 2 — Run the log query

1. Open **law-az104lab13** (search for it, or find it in the resource group) and select **Logs** from the left-hand menu.
2. If a query-builder/example panel opens automatically, dismiss or scroll past it to the empty query box.
3. Confirm the box is in **KQL mode** (there's a toggle near simple/KQL mode if the portal offers both for this table), then paste and run:
   ```kusto
   StorageBlobLogs
   | summarize count() by OperationName
   ```
4. If the result is empty, that's expected for the first several minutes after deploying — diagnostic data needs a little time to start flowing, and blob logs specifically need some blob activity to have occurred. Generate a little (even a failed list call against the account) and re-run after a few minutes.

## Part 3 — Run the metrics query, and see simple mode generate it

1. Still in **Logs**, clear the query box and run:
   ```kusto
   AzureMetrics
   | where ResourceProvider == "MICROSOFT.STORAGE"
   | summarize avg(Average) by bin(TimeGenerated, 1h)
   ```
2. Now switch the query box to **simple mode** (if available for this workspace) and rebuild roughly the same filter using the column/value pickers instead of typing KQL — filter the table to `AzureMetrics`, add a filter on `ResourceProvider`.
3. Look for a "toggle to KQL" or "show query" affordance in simple mode. If your portal still offers it, click it — you'll see it reconstructs KQL very close to what you typed by hand in step 1. This is the moment worth pausing on: simple mode isn't a different querying engine, it's a UI sitting on top of the same KQL you just wrote directly.

## Part 4 — Read the alert rule

1. In the search bar, go to **Monitor → Alerts → Alert rules**.
2. Open `alert-az104lab13-transactions`.
3. Look at the **Condition**: metric = `Transactions`, aggregation = Total, threshold = the value you deployed with (default 1000), evaluated over a 1-hour window, checked every 5 minutes.
4. Look at **Actions**: it points at `ag-az104lab13`. Click through to confirm the email receiver matches the `contactEmail` you deployed with.

This is the same metric-alert-plus-action-group shape as AZ-900 Lab 7 — if you want the full walkthrough of an alert rule's anatomy, that lab's walkthrough covers it in more depth; this lab's new material is everything in Parts 1-3 above.

## Part 5 — Flow logs, if you did the optional manual task

Skip this part if you didn't run the `az network watcher flow-log create` command from the lab README.

1. Search for **Network Watcher** in the portal.
2. Select **Flow logs** from the left-hand menu.
3. Find `fl-az104lab13-demo` and open it.
4. Confirm the **Target NSG**, the **Storage account** (if configured) or **Log Analytics workspace** destination, and that **Traffic Analytics** is off unless you explicitly turned it on.
5. If you're done looking at it, disable or delete it now — this is the one resource in this entire lab that keeps billing for as long as it stays enabled, and it doesn't get cleaned up by deleting `rg-az104-lab13`.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Locate a diagnostic setting scoped to a sub-resource** (blob service) versus one scoped to the parent resource (the storage account itself), and explain why both exist separately.
- **Run a KQL query against both a logs table and a metrics table** in the same workspace, and read the result grid for each.
- **Demonstrate that the portal's simple query mode generates real KQL** underneath its filter UI, rather than treating the two as separate systems.
- **Read a metric alert's full condition and action configuration**, building on the anatomy first introduced in AZ-900 Lab 7.
- **Find flow logs in the Network Watcher blade** (not the resource group they're protecting) and explain why that resource's billing and lifecycle are intentionally separate from the rest of this lab.
