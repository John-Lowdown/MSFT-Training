# Lab 03 — Resource Locks, Cost Budgets & Resource Moves

**AZ-104 domain:** Manage Azure identities and governance (20–25%) — Manage Azure subscriptions and governance
**Cost:** near-$0 (two empty storage accounts; budgets and action groups carry no charge)
**Time:** ~25 minutes

## What you'll build

Two storage accounts in the same resource group — one protected by a **`CanNotDelete` lock**, one left unlocked — plus a **monthly cost budget** scoped to the resource group with **two notification thresholds**: 80% of actual spend and 100% of forecasted spend, both wired to an **action group**. The manual tasks then use the locked/unlocked pair to demonstrate, live, that a lock blocks resource *moves* too, not just deletes — AZ-900 Lab 7 only showed the delete side of that story.

## Deploy

```bash
az group create --name rg-az104-lab03 --location eastus

az deployment group create \
  --resource-group rg-az104-lab03 \
  --template-file main.bicep \
  --parameters contactEmail=you@example.com
```

## Verify

```bash
az resource lock list --resource-group rg-az104-lab03 -o table

az consumption budget show \
  --budget-name budget-az104-lab03 \
  --query "{name:name, amount:amount, notifications:notifications}" -o json
```

In the portal: **rg-az104-lab03 → the locked storage account → Locks** to see the `CanNotDelete` lock, and **Cost Management + Billing → Budgets** to see both thresholds on `budget-az104-lab03`.

## Manual tasks (can't be done by Bicep)

1. **Create a throwaway target resource group for the move:**

   ```bash
   az group create --name rg-az104-lab03-movetarget --location eastus
   ```

2. **Try to move the locked storage account — watch it fail:**

   ```bash
   LOCKED_NAME=$(az deployment group show --resource-group rg-az104-lab03 --name main --query "properties.outputs.lockedStorageAccountName.value" -o tsv)

   az resource move \
     --destination-group rg-az104-lab03-movetarget \
     --ids $(az storage account show --name $LOCKED_NAME --resource-group rg-az104-lab03 --query id -o tsv)
   ```

   This fails with an error naming the `CanNotDelete` lock directly — moves are blocked by the same lock that blocks deletes, because a move is implemented as a delete from the source scope plus a create in the destination. This is the detail most students miss: they remember "locks block deletes" and stop there.

3. **Move the unlocked storage account instead — this succeeds:**

   ```bash
   UNLOCKED_NAME=$(az deployment group show --resource-group rg-az104-lab03 --name main --query "properties.outputs.unlockedStorageAccountName.value" -o tsv)

   az resource move \
     --destination-group rg-az104-lab03-movetarget \
     --ids $(az storage account show --name $UNLOCKED_NAME --resource-group rg-az104-lab03 --query id -o tsv)
   ```

4. **Review Advisor's cost recommendations — read-only tour.** In the portal, go to **Advisor → Cost**. Be honest with yourself here: a brand-new subscription with two nearly-empty storage accounts almost certainly won't have meaningful recommendations yet, because Advisor needs real usage history to generate anything personalized. This is the same honesty AZ-900's budget lab used — don't expect magic from a lab-scale deployment.

## Clean up

The lock has to come off before the lab resource group can delete — and since the unlocked storage account moved to a second resource group, that one needs cleanup too:

```bash
az lock delete \
  --name lab03-cannot-delete \
  --resource-group rg-az104-lab03 \
  --resource-name $LOCKED_NAME \
  --resource-type Microsoft.Storage/storageAccounts

az group delete --name rg-az104-lab03 --yes --no-wait
az group delete --name rg-az104-lab03-movetarget --yes --no-wait
```

## Lecture talking points

- **A resource lock blocks moves, not just deletes.** This is a commonly-missed exam detail — a `CanNotDelete` lock stops `az resource move`/portal Move just as hard as it stops delete, because Azure implements a cross-resource-group move as delete-then-recreate under the hood. Students who only memorize "CanNotDelete blocks deletion" get tripped up by a move-scenario question.
- **Budgets support more than one threshold, and more than one signal.** This lab wires 80% of *actual* spend and 100% of *forecasted* spend to the same action group — real budgets routinely carry 2–3 thresholds mixing both threshold types, not the single-threshold setup AZ-900 Lab 5 used.
- **Budgets can scope below the subscription.** This budget's `filter` targets one resource group by name — worth contrasting with a subscription-wide budget, which has no filter at all. Scoped budgets are how real teams track spend per project or per environment without needing separate subscriptions.
- **Advisor needs usage history — it's not an instant rule engine.** Unlike a Policy or a static alert threshold, Advisor's recommendations are generated from observed behavior over time. A fresh subscription showing no cost recommendations is expected, not broken — say this out loud before the live demo so a blank Advisor tab doesn't look like something failed.
- **Direct callback to AZ-900 Lab 5 (budgets) and Lab 7 (locks).** Lab 5 taught a single-threshold budget notifying on actual spend; this lab adds a second threshold and a second threshold *type*. Lab 7 taught that a lock blocks deletes; this lab extends that to moves — same mechanism, a detail most study guides under-emphasize.

## What you learned

By completing this lab, you can now:

- Demonstrate, from a live failed command, that a **`CanNotDelete` lock blocks resource moves**, not only deletes.
- Configure a **cost budget with multiple notification thresholds** mixing actual and forecasted spend, scoped to a specific resource group.
- Use **`az resource move`** to relocate a resource between resource groups, and explain why Azure implements a move as an underlying delete-and-recreate.
- Describe what **Azure Advisor's Cost recommendations** tab does, and explain why a low-usage subscription may show nothing meaningful yet.
- Remove a resource lock as the required first step before deleting (or moving) a locked resource.
