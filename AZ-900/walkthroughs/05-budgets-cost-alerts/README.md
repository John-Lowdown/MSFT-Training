# Walkthrough — Budgets & Cost Alerts (Lab 5)

A guided, portal-first walkthrough of what [Lab 5](../../labs/05-budgets-cost-alerts/) deploys. The lab's own README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for reading the budget in Cost Management and seeing, honestly, why you probably won't get an email during this demo.

**Prerequisite:** Lab 5 is already deployed (`az deployment sub create ...` from the lab README).

## Part 1 — Find the budget and its three thresholds

1. In the portal, go to **Cost Management + Billing** → your subscription's scope → **Cost Management** → **Budgets**.
2. Open `az900-lab05-monthly-budget`.
3. Confirm the monthly amount and all three notification thresholds: 50% Actual, 80% Actual, and 100% Forecasted — the exact set the lab deployed, now readable as portal configuration instead of Bicep JSON.

## Part 2 — Look at real spend against it, however small

1. Go to **Cost Management** → **Cost analysis**, scoped to your subscription.
2. Set the view to the current billing month. Unless you've left other labs running, this will likely show near-$0 spend — which is itself worth pointing out: a budget is watching real, tiny numbers, not a hypothetical.
3. Compare this number against the budget amount you set — you can see directly why none of the three thresholds have fired yet.

## Part 3 — The honest part: this demo probably won't email you

1. Unlike Lab 7's Monitor alert (which needs 5 GB of storage usage to fire) or Lab 8's Policy deny (which fires instantly on a real deployment), this budget's thresholds are tied to your **actual subscription spend for the month** — something a short lab session has essentially no ability to move.
2. This is the same "notify, don't act, and don't expect it to fire on demand" pattern that shows up across all three of these labs — worth naming explicitly so a quiet inbox doesn't read as "the budget didn't work."
3. If you want to see a notification actually arrive, the more realistic path is deploying this against a subscription with real ongoing spend and a deliberately low budget amount — not something to do with a fresh demo subscription.

## Part 4 — Confirm the scope, and where else a budget could live

1. Back on the budget's own page, check **Scope** — this lab deploys at the subscription level.
2. In **Cost Management**, note that budgets can also be created scoped to a single resource group or a management group instead — this lab picked subscription scope because that's what AZ-900's objectives explicitly reference, not because it's the only option.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Read a budget's amount and all three notification thresholds** directly in Cost Management, and connect the Actual/Actual/Forecasted split to real portal fields rather than only a Bicep template.
- **Compare current spend against a budget** using Cost analysis, and explain why a fresh demo subscription won't realistically cross any threshold.
- **Recognize the "notify, don't act, don't expect it on demand" pattern** shared across Lab 5 (spend), Lab 7 (a storage metric), and Lab 8 (policy compliance scanning) — three different signals, the same underlying shape.
- **State that budgets can be scoped to a resource group or management group**, not only a subscription, even though this lab deploys the subscription-scoped version AZ-900 explicitly tests.
