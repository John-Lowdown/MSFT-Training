# Walkthrough — Resource Locks, Cost Budgets & Resource Moves (Lab 03)

A guided, portal-first walkthrough of what [Lab 03](../../labs/03-governance-tags-cost/) deploys, plus the manual move demo. The lab README covers the Bicep deploy/verify/cleanup commands and the `az resource move` CLI steps — this walkthrough is for watching the same move succeed and fail from the portal's own buttons, and for reading the budget's two thresholds directly.

**Prerequisite:** Lab 03 is already deployed (`az deployment group create ...` from the lab README) and you have the resource group open in the [Azure Portal](https://portal.azure.com).

## Part 1 — Read the budget's two thresholds

1. In the portal search bar, go to **Cost Management + Billing**.
2. Select **Budgets** in the left menu.
3. Open `budget-az104-lab03`.
4. Look at the **Alert conditions** section — you'll see two rows: one at **80%** against **Actual** spend, one at **100%** against **Forecasted** spend. Both point at the same action group.
5. Click through to the action group (`ag-az104-lab03`) and confirm the email receiver you passed as `contactEmail` when deploying.

Notice this budget's scope — it was created with a resource-group filter, so it only tracks spend inside `rg-az104-lab03`, not the whole subscription.

## Part 2 — Try to move the locked storage account from the portal

1. Open the resource group and click into the storage account tagged `moveTest: locked`.
2. From its **Overview** page, click **Move** → **Move to another resource group**.
3. Select (or type) `rg-az104-lab03-movetarget` as the destination (create it first if you haven't run the manual CLI step yet) and click through the validation step.
4. Watch it fail. The validation error names the lock directly — something like *"...cannot be moved because it has a lock of level CanNotDelete..."*

This is the moment worth pausing on: the same lock that blocks delete blocks this move too, and the portal's own pre-move validation catches it before you even reach the confirm button.

## Part 3 — Move the unlocked storage account successfully

1. Go back to the resource group and open the storage account tagged `moveTest: unlocked`.
2. Click **Move** → **Move to another resource group**, select `rg-az104-lab03-movetarget` again, and run the validation.
3. This time validation passes. Confirm the move and wait for it to complete (a few minutes).
4. Open `rg-az104-lab03-movetarget` afterward and confirm the storage account now lives there.

## Part 4 — Tour Advisor's Cost recommendations

1. In the portal search bar, go to **Advisor**.
2. Select the **Cost** tab.
3. Look at whatever is there. On a subscription with light usage — like the one this lab just created — don't be surprised if it shows few or no recommendations. Advisor needs real usage history to generate personalized suggestions; it isn't a static rule checker like Policy.
4. If your subscription has other, older workloads running in it, you may see real recommendations here (unused disks, idle VMs, reserved-instance suggestions) — worth reading through if present, but not something this lab's own resources will generate.

## Part 5 — Clean up

1. Back on the locked storage account's **Locks** blade, select `lab03-cannot-delete` and click **Delete**.
2. Now retry the **Move** from Part 2 — it succeeds this time, or you can simply delete both resource groups directly.
3. Delete `rg-az104-lab03` and `rg-az104-lab03-movetarget` (or run the CLI commands in the [lab README's cleanup section](../../labs/03-governance-tags-cost/README.md#clean-up) — same effect, faster).

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Read a budget's notification thresholds** and distinguish an actual-spend threshold from a forecasted-spend threshold.
- **Demonstrate, from a failed portal Move attempt, that a resource lock blocks moves as well as deletes** — and read the validation error that names the lock directly.
- **Successfully move a resource between resource groups** using the portal's Move action, and confirm it landed in the destination group.
- **Navigate to Advisor's Cost tab** and explain why a low-usage subscription may show little or nothing there yet.
- **Remove a resource lock deliberately**, as the required first step before moving or deleting a locked resource.
