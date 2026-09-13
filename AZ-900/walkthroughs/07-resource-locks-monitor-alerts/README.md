# Walkthrough — Resource Locks & Monitor Alerts (Lab 7)

A guided, portal-first walkthrough of what [Lab 7](../../labs/07-resource-locks-monitor-alerts/) deploys. The lab's own README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for actually clicking around the portal afterward, so the two exam concepts it demonstrates (a resource lock, and a Monitor metric alert) stop being table entries and become things you've seen fail and fire.

**Prerequisite:** Lab 7 is already deployed (`az deployment group create ...` from the lab README) and you have the resource group open in the [Azure Portal](https://portal.azure.com).

## Part 1 — Find the lock

1. Open your resource group (`rg-az900-lab07`) and click into the storage account inside it.
2. In the left-hand menu, under **Settings**, find **Locks**.
3. You'll see one lock: `lab07-cannot-delete`, level **Delete** (the portal's label for `CanNotDelete`).

Notice what's *not* here: no mention of who can or can't see or use this lock based on their role. That's the point — a lock isn't an RBAC object, so it doesn't have role assignments of its own.

## Part 2 — Try to delete it anyway

1. From the storage account's **Overview** page, click **Delete**.
2. Confirm the deletion prompt.
3. Watch it fail. The error names the lock directly — something like *"...cannot be deleted because it has a lock of level CanNotDelete..."*

This is the moment worth pausing on: **it doesn't matter what role you have.** Try it as a subscription Owner and it still fails, because the lock isn't checking your permissions — it's blocking the action itself.

4. Now go up a level: open the resource group's **Overview** and click **Delete resource group**. Type the resource group name to confirm, and submit.
5. Watch that fail too — deleting a resource group requires deleting everything inside it, and the locked storage account can't be deleted, so the whole operation is blocked.

## Part 3 — Find the alert rule

1. In the search bar, go to **Monitor**, then **Alerts** in the left menu, then **Alert rules**.
2. Find `alert-az900-lab07-usedcapacity` and open it.
3. Look at the **Condition**: metric = `UsedCapacity`, aggregation = Average, threshold = 5 GB (shown in bytes — 5368709120), evaluated over a 6-hour window, checked every hour.
4. Look at **Actions**: it points at the action group `ag-az900-lab07`. Click through to that action group and confirm the email receiver address you passed as `contactEmail` when you deployed.

## Part 4 — Look at the actual metric (and why it won't fire today)

1. Still in **Monitor**, go to **Metrics**, and select your storage account as the scope.
2. Add the metric `UsedCapacity`.
3. You'll see a line sitting at (or extremely close to) zero — this is an empty storage account from a 15-minute lab, not a production workload.

This is worth saying out loud: **the alert is correctly configured, but it will realistically never fire during this demo**, because you'd need to actually upload several gigabytes of data first. That's fine — the teaching goal here is reading and understanding an alert rule's anatomy (metric, condition, evaluation window, action group), not watching it trigger. If you want to actually see it fire, the metric alert is real and will trigger on any storage account that legitimately crosses 5 GB used capacity.

## Part 5 — Remove the lock and clean up

Back in the portal, on the storage account's **Locks** blade:

1. Select `lab07-cannot-delete` and click **Delete**.
2. Now retry deleting the resource group from Part 2 — it succeeds this time.

(Or just run the CLI commands in the [lab README's cleanup section](../../labs/07-resource-locks-monitor-alerts/README.md#clean-up) — same effect, faster.)

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Locate and read a resource lock** in the Azure Portal, and state what level (`CanNotDelete` vs. `ReadOnly`) is applied and to what.
- **Demonstrate, from direct experience, that a lock overrides RBAC permissions** — a subscription Owner cannot delete a locked resource until the lock itself is removed, which is one of the most commonly tested distinctions in the governance domain.
- **Explain why a lock on one resource can block deletion of an entire resource group** — the resource group can't finish deleting everything inside it while one locked resource refuses to go.
- **Read a Monitor metric alert's configuration** end to end: which metric it watches, how it aggregates and evaluates that metric over time, what threshold triggers it, and which action group it notifies.
- **Distinguish a correctly-configured alert from a fired alert** — understanding that an alert rule existing and being enabled is not the same as it having triggered, and why a short lab session won't realistically cross a 5 GB threshold.
- **Remove a resource lock deliberately**, as the required first step before deleting a locked resource or any resource group containing one.
