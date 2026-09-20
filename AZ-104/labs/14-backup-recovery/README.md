# Lab 14 — Azure Backup: Recovery Services Vault, Backup Vault & VM Restore

**AZ-104 domain:** Monitor and maintain Azure resources (10–15%) — Implement backup and recovery
**Cost:** $0 for the vault and policy alone. Backed-up data is billed per protected instance plus consumed storage — roughly a couple of cents per GB-month for a small VM, cheap for a short demo — but **only if you do the optional manual task of actually enabling backup on a real VM.** Skip that and just deploy/inspect the vault and policy, and this lab costs nothing. The optional Site Recovery capstone task at the end is genuinely not cheap if left running — see its own warning below.
**Time:** ~30 minutes for the vault, policy, and the core backup/restore manual tasks. The optional Site Recovery section is a separate, much longer exploratory exercise — budget extra time for it deliberately, don't treat it as a quick add-on.

## What you'll build

A **Recovery Services vault** and a **daily backup policy** (`AzureIaasVM` type, runs at a fixed UTC time, retains daily points for 7 days) — both real, deployable ARM resources. What this lab deliberately does *not* build in Bicep is the actual protection of a VM: associating a VM with a vault+policy is a data-plane, wizard-driven operation with no clean standalone ARM resource, so that — along with on-demand backup, restore, and an optional Site Recovery capstone — is the bulk of this lab's **Manual tasks** section below.

Alongside the Recovery Services vault, this lab also builds a **Backup vault** (`Microsoft.DataProtection/backupVaults`, resource name `bv-az104lab14`) and a **blob operational-backup policy** on it (`policy-az104lab14-blob`). This is a genuinely separate resource type — a different resource provider namespace, a different underlying backup stack — not a newer flavor of the Recovery Services vault above. The exam's own skill list names this exact distinction ("Create a Recovery Services vault vs. an Azure Backup vault — when each applies"), and Backup vault is what the newer "Azure Backup" protection of blobs, managed disks, and a few other workload types is actually built on. As with VM protection, this lab deploys the vault and policy but leaves actually protecting a specific storage account (granting the vault's identity the RBAC role it needs, then enabling protection) as a manual task.

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

az dataprotection backup-vault show \
  --resource-group rg-az104-lab14 \
  --vault-name bv-az104lab14 -o table
```

In the portal: **rg-az104-lab14 → rsv-az104lab14 → Overview**, and **Backup policies** (under **Manage**) to see the daily schedule and 7-day retention read back exactly as deployed. Separately, **rg-az104-lab14 → bv-az104lab14 → Overview** for the Backup vault, and its **Backup policies** blade to see the blob policy's retention rule.

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

### e) Optional — actually protect a storage account with the Backup vault's blob policy

Not required to complete this lab; the Bicep already deploys the Backup vault and its policy, which covers the exam's "create a Backup vault" and "create and configure a backup policy" bullets on their own. This step is for seeing an actual protected instance if you want to.

First, grant the vault's system-assigned identity the **Storage Account Backup Contributor** role on the storage account you want to protect (portal: storage account → **Access control (IAM)** → **Add role assignment** → assign to `bv-az104lab14`'s managed identity). Then, portal path: **bv-az104lab14 → Backup instances → + Backup** → choose **Blob Storage** as the datasource type → pick the storage account → pick `policy-az104lab14-blob`. Blob operational backup is continuous once configured (it relies on the storage account's own soft delete, versioning, and change feed settings being enabled) rather than something you trigger on demand the way VM backup is.

### f) Configure backup reports and alerts

Not covered anywhere else in this lab, and a distinct exam sub-bullet from "perform backup and restore operations." **Backup Center → Backup Reports** is where cross-vault reporting lives — it needs a Log Analytics workspace as its reporting sink (reuse Lab 13's `law-az104lab13` if it's still deployed) configured once via **Backup Center → Backup Reports → Configure**. Give it time to populate; reports are built from data that accumulates over days, not instantly after the first backup job.

For alerts, either the classic per-vault path (**rsv-az104lab14 → Backup alerts**, under **Monitoring**) or the newer, unified **Backup Center → Alerts** view shows backup-job failures and other backup-health events across your vaults. A default "backup failure" alert typically exists out of the box — open it to see its configured severity and any action group it notifies, or create a new alert rule pointed at an action group (the same action-group concept Lab 13 already wired up for its metric alert, just triggered by a backup-health signal instead of a storage metric).

## Clean up

**A Recovery Services vault cannot be deleted while it still has protected items** — this is the real gotcha in this lab, and which cleanup path applies depends entirely on whether you did manual task (a).

**If you only deployed the vaults and policies, and skipped the manual tasks:**
```bash
az group delete --name rg-az104-lab14 --yes --no-wait
```
Nothing is protected, so nothing blocks the delete — this removes the Recovery Services vault (`rsv-az104lab14`), the Backup vault (`bv-az104lab14`), and both policies in one shot, since all four resources live inside `rg-az104-lab14`.

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

**If you protected a storage account with the Backup vault's blob policy (manual task e):** disable that protection first too:
```bash
az dataprotection backup-instance stop-protection \
  --resource-group rg-az104-lab14 \
  --vault-name bv-az104lab14 \
  --backup-instance-name <backup-instance-name>
```
**Honesty note:** the Recovery Services vault's "can't delete while holding protected items" behavior is well-documented and confirmed above. Whether the Backup vault enforces the identical hard block (vs. allowing deletion and orphaning the data, or some other behavior) is something this README hasn't independently verified — treat it as likely similar given how alike the two vault types' protection model is, but confirm directly against your subscription (or current Microsoft Learn docs) before relying on that assumption, rather than trusting this claim outright.

If you also did the optional Site Recovery capstone, disable replication and remove any target-region VM/disks separately first — those can live in a different resource group than `rg-az104-lab14` and won't be touched by the delete above.

## Lecture talking points

- **Recovery Services vault vs. Backup vault is a named exam bullet, not a footnote — and now this lab makes it concrete instead of a comparison-table abstraction.** They're genuinely different resource types (`Microsoft.RecoveryServices/vaults` vs. `Microsoft.DataProtection/backupVaults`), with different portal experiences and different underlying backup stacks. Recovery Services vault is what VM backup (and Site Recovery) use — a **scheduled-snapshot** model, backups run at set times per the policy's schedule. Backup vault's blob backup is **operational backup** — continuous, point-in-time-restore protection, not a series of scheduled snapshots at all. Knowing which vault type a given workload actually uses, and that "operational" backup behaves differently in kind from scheduled backup, is exactly the distinction the exam is testing when it asks "vault vs. vault."
- **A vault that refuses to delete itself while it holds protected items is the same *shape* of gotcha you've now seen three times.** AZ-900 Lab 7's resource lock blocks deletion until the lock is removed. AZ-900 Lab 8's policy assignment has to be deleted before its definition. Now a Recovery Services vault blocks deletion until protection is explicitly disabled. Naming this pattern explicitly — "some Azure resources actively resist deletion until you unwind what's attached to them" — is worth doing out loud across all three examples, because the exam tests each one individually and students often don't connect them.
- **A backup policy is "define once, apply broadly," the same shape as an Azure Policy definition.** One policy, schedule and retention set once, reused across every VM you protect with it — a direct, intentional one-sentence echo of the governance domain's Lab 02, just applied to data protection instead of compliance.
- **Backup and Site Recovery solve genuinely different problems, even sharing a vault type.** This is a named, frequently tested exam pair: **Backup** is point-in-time recovery from accidental loss or corruption, restoring *within the same region*. **Site Recovery** is continuous replication for disaster recovery, restoring *into a different region* entirely. Mixing these up — thinking Backup protects against a regional outage, or that Site Recovery is for routine "oops I deleted a file" recovery — is a common and costly exam trap.
- **"Create new" vs. "Replace existing" vs. "Restore disks only" are three different recovery strategies, not three UI labels for the same action.** Each has a different blast radius on the original VM — know which one you'd actually reach for in a given incident, not just that all three exist.
- **Why the VM-to-vault association itself isn't Bicep.** Enabling backup on a specific VM is a data-plane operation tied to that VM's current state, not a declarative "this configuration should exist" statement — which is exactly the same reasoning that kept Lab 02's remediation task and the flow-log task in Lab 13 out of their Bicep files too. Recognizing *why* something resists Infrastructure-as-Code treatment is as exam- and job-relevant as knowing the CLI command for it.
- **This lab is $0 until you act on a VM (or a storage account).** The vaults and policies are governance-shaped resources with no cost of their own — cost only enters once real backup data exists, which is a deliberate design choice worth calling out the same way Lab 06 called out being "the first lab with real hourly billing."
- **Reports and alerts are a separate exam bullet from "perform backup and restore," and it's easy to assume they're the same skill.** Actually running a backup and restore proves the data-protection mechanics work. Reports (in Backup Center, sourced from a Log Analytics workspace) and alerts (per-vault or unified in Backup Center) are the *operational* half — knowing a backup silently failed three nights running, across every vault you manage, without having to click into each one. A course/lab that only ever shows a successful on-demand backup never exercises the failure-visibility half of the skill at all.

## What you learned

By completing this lab, you can now:

- Deploy a **Recovery Services vault** and a reusable **AzureIaasVM backup policy** (schedule + retention) via Bicep.
- Deploy a **Backup vault** (`Microsoft.DataProtection/backupVaults`) and a **blob operational-backup policy** via Bicep, and explain concretely why it's a separate resource type from a Recovery Services vault rather than a newer version of the same thing.
- Enable backup protection on a running VM, through both the portal's **Data protection** blade and `az backup protection enable-for-vm`.
- Trigger an **on-demand backup** instead of waiting for the scheduled job, with `az backup protection backup-now`.
- Distinguish the three VM restore strategies — **Create new**, **Replace existing**, **Restore disks only** — and explain the differing risk to the original VM for each.
- Explain the exam-tested distinction between **Azure Backup** (same-region, point-in-time recovery) and **Azure Site Recovery** (cross-region, continuous disaster recovery replication).
- Explain the difference between **scheduled-snapshot backup** (VM backup, via Recovery Services vault) and **operational/continuous backup** (blob backup, via Backup vault).
- Locate **Backup Center's reporting and alerting views** and explain what a Log Analytics workspace contributes to backup reporting.
- Correctly sequence cleanup of a vault with protected items: disable protection (and decide on backup-data retention) *before* attempting to delete the vault or its resource group.
