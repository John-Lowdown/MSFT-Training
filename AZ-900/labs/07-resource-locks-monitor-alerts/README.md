# Lab 7 — Resource Locks & Monitor Alerts

**AZ-900 domain:** Azure Management & Governance — Resource Locks / Azure Monitor
**Cost:** near-$0 (an empty storage account; platform metric alerts and action groups carry no charge)
**Time:** ~15 minutes

## What you'll build

A storage account protected by a **`CanNotDelete` resource lock**, plus an **Azure Monitor metric alert** on that account's `UsedCapacity` metric wired to an **action group** that emails you when used capacity crosses 5 GB. Two separately-named exam tools, in one lab: governance (the lock) and monitoring (the alert).

## Deploy

```bash
az group create --name rg-az900-lab07 --location eastus

az deployment group create \
  --resource-group rg-az900-lab07 \
  --template-file main.bicep \
  --parameters contactEmail=you@example.com
```

## Verify

```bash
az resource lock list --resource-group rg-az900-lab07 -o table

az monitor metrics alert show \
  --name alert-az900-lab07-usedcapacity \
  --resource-group rg-az900-lab07 \
  --query "{name:name, enabled:enabled, severity:severity}" -o json
```

In the portal: **rg-az900-lab07 → the storage account → Locks** to see the `CanNotDelete` lock, and **Monitor → Alerts → Alert rules** to see the metric alert scoped to that storage account.

**A demo worth doing live:** try to delete the resource group right now.

```bash
az group delete --name rg-az900-lab07 --yes --no-wait
```

It fails — the locked storage account blocks the whole resource group from deleting, even though you almost certainly have Owner or Contributor rights on it. That's the exam-tested point made concrete: **a resource lock is not an RBAC concept.**

## Clean up

The lock has to come off before anything can be deleted — this is not optional:

```bash
STORAGE_NAME=$(az deployment group show --resource-group rg-az900-lab07 --name main --query "properties.outputs.storageAccountName.value" -o tsv)

az lock delete \
  --name lab07-cannot-delete \
  --resource-group rg-az900-lab07 \
  --resource-name $STORAGE_NAME \
  --resource-type Microsoft.Storage/storageAccounts

az group delete --name rg-az900-lab07 --yes --no-wait
```

## Lecture talking points

- **A resource lock is not an RBAC concept.** `CanNotDelete` blocks deletion for *everyone* touching the resource — including subscription Owners — until someone removes the lock itself. `ReadOnly` is stricter still: it blocks modification too, allowing only reads. This lab deliberately makes the failed `az group delete` attempt the centerpiece, not a footnote — students who only read about this in a table forget it by the next module; students who watch their own delete command fail don't.
- **Why cleanup needs an extra step.** The locked storage account blocks the *entire resource group* from deleting, not just itself — a good moment to reinforce that a lock's scope can sit above or below where you're trying to act.
- **Three named monitoring tools, and this lab only touches one.** Azure Monitor (this lab) collects metrics/logs and can act on them via alerts; Azure Advisor gives personalized recommendations from your own resource configuration; Azure Service Health reports incidents/maintenance for the specific services and regions you use. The exam tests these as three separate tools that answer different questions — worth naming all three even though only Monitor gets a hands-on lab here.
- **Metric alerts vs. budgets (Lab 5), same shape, different signal.** Both are "notify, don't act" mechanisms wired to thresholds — a budget watches spend, this alert watches a resource metric. Neither one stops or shuts down anything on its own; both need to be wired to something else (an Automation runbook, a Logic App) for real automated response, which is out of scope for AZ-900 but worth a one-sentence mention.
- **Why `severity: 3` and a 6-hour window.** Metric alert severity (0–4, 0 highest) and evaluation window are configuration choices, not fixed values — this lab picks moderate defaults appropriate for a capacity-creep warning rather than an urgent outage signal. AZ-900 doesn't test these specific numbers, but understanding that they're tunable prevents students from thinking alerts are one-size-fits-all.
- **This is the direct hands-on companion to Module 4 (resource locks) and Module 6 (Azure Monitor)** in the video course outline — the published study guide explicitly names this as "Lab 7" and diagrams it in its Appendix.

## What you learned

By completing this lab, you can now:

- Explain the difference between a **resource lock** and an **RBAC role assignment** — and demonstrate, not just describe, that a lock blocks an action for everyone regardless of permissions.
- Distinguish `CanNotDelete` from `ReadOnly` and pick the right one for a given governance need.
- Describe what **Azure Monitor** watches (metrics and logs from your own resources) and how a **metric alert** turns a threshold crossing into a notification via an **action group**.
- Place Azure Monitor correctly alongside **Azure Advisor** and **Azure Service Health** as three separate, exam-named monitoring tools that answer three different questions.
- Recognize the "notify, don't act" pattern shared by budgets (Lab 5) and metric alerts (this lab) — and know what it would take to turn a notification into an automated response.
