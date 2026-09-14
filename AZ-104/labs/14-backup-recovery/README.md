# Lab 14 — Azure Backup: Recovery Services Vault & VM Restore

**AZ-104 domain:** Monitor and maintain Azure resources (10–15%) — Implement backup and recovery
**Cost:** $0 for the vault and policy alone. Backed-up data is billed per protected instance plus consumed storage — roughly a couple of cents per GB-month for a small VM, cheap for a short demo — but **only if you do the optional manual task of actually enabling backup on a real VM.** Skip that and just deploy/inspect the vault and policy, and this lab costs nothing. The optional Site Recovery capstone task at the end is genuinely not cheap if left running — see its own warning below.
**Time:** ~30 minutes for the vault, policy, and the core backup/restore manual tasks. The optional Site Recovery section is a separate, much longer exploratory exercise — budget extra time for it deliberately, don't treat it as a quick add-on.

## What you'll build

A **Recovery Services vault** and a **daily backup policy** (`AzureIaasVM` type, runs at a fixed UTC time, retains daily points for 7 days) — both real, deployable ARM resources. What this lab deliberately does *not* build in Bicep is the actual protection of a VM: associating a VM with a vault+policy is a data-plane, wizard-driven operation with no clean standalone ARM resource, so that — along with on-demand backup, restore, and an optional Site Recovery capstone — is the bulk of this lab's **Manual tasks** section below.

## Deploy

```bash
az group create --name rg-az104-lab14 --location eastus

az deployment group create \
  --resource-group rg-az104-lab14 \
  --template-file main.bicep
```

## Verify

```bash
az backup vault show --resource-group rg-az104-lab14 --name rsv-az104lab14 -o table

az backup policy show \
  --resource-group rg-az104-lab14 \
  --vault-name rsv-az104lab14 \
  --name policy-az104lab14-daily -o table
```

In the portal: **rg-az104-lab14 → rsv-az104lab14 → Overview**, and **Backup policies** (under **Manage**) to see the daily schedule and 7-day retention read back exactly as deployed.

## Manual tasks (can't be done by Bicep)

This is the bulk of the lab — everything below is data-plane/wizard-shaped and has no standalone ARM resource to author.

### a) Enable backup on an existing VM

You need a VM to protect first. If Lab 06's `vm-az104lab06` is still deployed, reuse it; otherwise, note that this step needs a running VM before it can do anything.

Portal path: open the VM → **Data protection** (under **Settings**, name varies slightly by portal version — may show as **Backup**) → select `rsv-az104lab14` as the vault and `policy-az104lab14-daily` as the policy → **Enable backup**.

CLI equivalent:
```bash
az backup protection enable-for-vm \
  --resource-group rg-az104-lab14 \
  --vault-name rsv-az104lab14 \
  --vm vm-az104lab06 \
  --policy-name policy-az104lab14-daily
```

> If the VM lives in a different resource group than the vault (likely, if you're reusing Lab 06's VM), pass its full resource ID instead of just the VM name — check `az backup protection enable-for-vm --help` for the exact flag your CLI version expects.

### b) Trigger an on-demand backup

Don't wait for the daily schedule — back it up right now:

```bash
az backup protection backup-now \
  --resource-group rg-az104-lab14 \
  --vault-name rsv-az104lab14 \
  --container-name <container-name> \
  --item-name vm-az104lab06 \
  --backup-management-type AzureIaasVM \
  --retain-until 30-09-2026
```

`container-name` and `item-name` come back from `az backup item list --resource-group rg-az104-lab14 --vault-name rsv-az104lab14 --backup-management-type AzureIaasVM -o table` once protection is enabled — the container name is usually the VM name prefixed with `iaasvmcontainer;`.

### c) Restore

Portal path: **rsv-az104lab14 → Backup items** → select the VM → select a restore point → **Restore VM**. You'll see three genuinely different strategies, each with a different blast radius on the original VM:
- **Create new** — restores to a brand-new VM, original untouched. Safest, most common choice.
- **Replace existing** — overwrites the original VM's disks in place. Higher risk, but useful when you specifically need the original VM's identity (same NICs, same resource ID) preserved.
- **Restore disks only** — restores just the disks as standalone managed disks, with no VM created at all, for when you want to attach them manually or inspect their contents.

CLI equivalent exists (`az backup restore restore-disks`) but is honestly heavier and more multi-step than the portal wizard for a full VM restore — you'd need to separately track the recovery point ID, the storage account to restore disks into, and then assemble a VM from the restored disks yourself. For this specific operation, doing it through the portal wizard is the practical choice, not a workaround.

### d) Optional capstone — Azure Site Recovery (exploratory, NOT a routine repeat lab)

Everything above is a normal lab exercise. This is not — treat it as optional and exploratory, something to try once to see the shape of it, not something to repeat every time you run this course. It needs a **second Azure region**, a **real VM kept running** long enough to actually replicate (continuously billable the whole time), and meaningfully more setup than anything else in this entire course.

Portal path: **rsv-az104lab14 → Site Recovery** (under **Getting Started**) → **Azure virtual machines** → **Replicate** → pick the source VM, then the target region, target resource group, and target VNet → **Enable replication**. Replication takes real time to complete an initial sync (often 30+ minutes to multiple hours depending on disk size). Once it reports a healthy state, go to **Site Recovery → Replicated items**, select the VM, and use **Failover** → pick a recovery point → **Commit** to actually fail it over to the second region.

If you try this, clean it up promptly: disable replication and delete any failed-over VM and its disks in the target region before leaving it — a replicated VM consumes storage continuously, and a committed failover leaves running compute in a second region that keeps billing until you remove it.

## Clean up

**A Recovery Services vault cannot be deleted while it still has protected items** — this is the real gotcha in this lab, and which cleanup path applies depends entirely on whether you did manual task (a).

**If you only deployed the vault and policy, and skipped the manual tasks:**
```bash
az group delete --name rg-az104-lab14 --yes --no-wait
```
Nothing is protected, so nothing blocks the delete.

**If you enabled backup on a VM (manual task a):** you must disable protection first and explicitly decide whether to keep or delete the backed-up data, *before* the vault or resource group can be deleted:
```bash
az backup protection disable \
  --resource-group rg-az104-lab14 \
  --vault-name rsv-az104lab14 \
  --container-name <container-name> \
  --item-name vm-az104lab06 \
  --backup-management-type AzureIaasVM \
  --delete-backup-data true

az group delete --name rg-az104-lab14 --yes --no-wait
```

If you also did the optional Site Recovery capstone, disable replication and remove any target-region VM/disks separately first — those can live in a different resource group than `rg-az104-lab14` and won't be touched by the delete above.

## Lecture talking points

- **A vault that refuses to delete itself while it holds protected items is the same *shape* of gotcha you've now seen three times.** AZ-900 Lab 7's resource lock blocks deletion until the lock is removed. AZ-900 Lab 8's policy assignment has to be deleted before its definition. Now a Recovery Services vault blocks deletion until protection is explicitly disabled. Naming this pattern explicitly — "some Azure resources actively resist deletion until you unwind what's attached to them" — is worth doing out loud across all three examples, because the exam tests each one individually and students often don't connect them.
- **A backup policy is "define once, apply broadly," the same shape as an Azure Policy definition.** One policy, schedule and retention set once, reused across every VM you protect with it — a direct, intentional one-sentence echo of the governance domain's Lab 02, just applied to data protection instead of compliance.
- **Backup and Site Recovery solve genuinely different problems, even sharing a vault type.** This is a named, frequently tested exam pair: **Backup** is point-in-time recovery from accidental loss or corruption, restoring *within the same region*. **Site Recovery** is continuous replication for disaster recovery, restoring *into a different region* entirely. Mixing these up — thinking Backup protects against a regional outage, or that Site Recovery is for routine "oops I deleted a file" recovery — is a common and costly exam trap.
- **"Create new" vs. "Replace existing" vs. "Restore disks only" are three different recovery strategies, not three UI labels for the same action.** Each has a different blast radius on the original VM — know which one you'd actually reach for in a given incident, not just that all three exist.
- **Why the VM-to-vault association itself isn't Bicep.** Enabling backup on a specific VM is a data-plane operation tied to that VM's current state, not a declarative "this configuration should exist" statement — which is exactly the same reasoning that kept Lab 02's remediation task and the flow-log task in Lab 13 out of their Bicep files too. Recognizing *why* something resists Infrastructure-as-Code treatment is as exam- and job-relevant as knowing the CLI command for it.
- **This lab is $0 until you act on a VM.** The vault and policy are governance-shaped resources with no cost of their own — cost only enters once real backup data exists, which is a deliberate design choice worth calling out the same way Lab 06 called out being "the first lab with real hourly billing."

## What you learned

By completing this lab, you can now:

- Deploy a **Recovery Services vault** and a reusable **AzureIaasVM backup policy** (schedule + retention) via Bicep.
- Enable backup protection on a running VM, through both the portal's **Data protection** blade and `az backup protection enable-for-vm`.
- Trigger an **on-demand backup** instead of waiting for the scheduled job, with `az backup protection backup-now`.
- Distinguish the three VM restore strategies — **Create new**, **Replace existing**, **Restore disks only** — and explain the differing risk to the original VM for each.
- Explain the exam-tested distinction between **Azure Backup** (same-region, point-in-time recovery) and **Azure Site Recovery** (cross-region, continuous disaster recovery replication).
- Correctly sequence cleanup of a vault with protected items: disable protection (and decide on backup-data retention) *before* attempting to delete the vault or its resource group.
