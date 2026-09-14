# Walkthrough — Storage Lifecycle, Versioning & Object Replication (Lab 05)

A guided, portal-first walkthrough of what [Lab 05](../../labs/05-storage-lifecycle-protection/) deploys. The lab README covers the Bicep deploy/verify/cleanup commands and the CLI-driven manual tasks — this walkthrough is for reading the resulting configuration in the portal and actually watching versioning and soft delete do something, which is otherwise invisible in a code review.

**Prerequisite:** Lab 05 is already deployed (`az deployment group create ...` from the lab README), and you've run the manual upload/overwrite/delete steps against the `logs/test.log` blob, with the resource group open in the [Azure Portal](https://portal.azure.com).

## Part 1 — Read the lifecycle management rule

1. Open `rg-az104-lab05` and click into the **source** storage account.
2. In the left menu, under **Data management**, select **Lifecycle management**.
3. Open the rule named `tier-cool-then-delete`.
4. On the **Details** tab, confirm the filter scope is `lab05data/logs/` and blob type is block blobs only.
5. On the **Base blobs** tab, confirm the actions: move to cool storage after 30 days, delete after 180 days — both measured from last modification.

This rule is live and correctly configured, but the portal has no "run now" button for a lifecycle policy — it genuinely waits for Azure's own evaluation cycle.

## Part 2 — Read the object replication policy

1. Still on the source account, select **Object replication** under **Data management**.
2. Open the replication rule. Confirm the source container and destination container are both `lab05data`, and the destination account matches your deployment.
3. Look at the rule's **Copy progress / status** column — with an empty container it should show as complete or near-complete quickly.
4. Open the **destination** storage account and check its own **Object replication** blade — it shows the same policy from the receiving side, read-only from here (the policy itself is managed from the source side).

## Part 3 — Watch versioning do something

1. On the source account, go to **Data storage → Containers**, open `lab05data`, and navigate into the `logs/` virtual folder.
2. Click on `test.log`.
3. Select the **Version history** (or **Versions**) tab. You should see two entries: the original upload and the overwrite you performed in the lab's manual tasks, each with its own timestamp and the current version marked.
4. Click the older version — you can preview or restore it. This is the concrete proof that versioning is doing something, not just a toggle in a properties blade.

## Part 4 — Watch soft delete do something

1. Back in the `logs/` folder listing, turn on **Show deleted blobs** (a toggle near the top of the blob list).
2. `test.log` now reappears, marked as deleted, with a countdown against the 7-day retention window configured in this lab's template.
3. Right-click (or select and use the toolbar) to **Undelete** it. It reappears in the normal listing as a live blob again.

This is the payoff moment for two lab resources that are otherwise just settings in a JSON blob: you deleted something, and soft delete gave it back.

## Part 5 — Confirm the file share

1. On the source account, select **Data storage → File shares**.
2. Open `lab05share` and confirm the quota (5 GiB) and access tier (Cool) match the template.
3. Note that this share has no relationship whatsoever to anything in Parts 1–4 — it's here purely to show that Azure Files lives in the same account as Blob Storage without the two services interacting.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Read a lifecycle management rule's filter and actions** end to end, and explain why it won't visibly act during a short demo.
- **Locate an object replication policy from both the source and destination side**, and read its copy status.
- **Find and restore a previous blob version** after an overwrite, using the container's version history.
- **Show deleted blobs and undelete one** within its soft-delete retention window, and state what happens once that window expires.
- **Locate an Azure Files share's quota and access tier**, and explain why it coexists with, but is unrelated to, the blob-level features in the same storage account.
