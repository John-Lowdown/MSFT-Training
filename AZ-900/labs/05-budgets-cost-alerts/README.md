# Lab 5 — Budgets & Cost Alerts

**AZ-900 domain:** Pricing, SLA & Lifecycle
**Cost:** $0 — budgets only watch spend, they don't cap it
**Time:** ~10 minutes

## What you'll build
A subscription-level monthly budget with three notification thresholds: email alerts at 50% and 80% of *actual* spend, and a forecasted-100% warning that fires before you've actually spent the full amount, based on trend.

## Deploy

```bash
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters budgetAmount=50 contactEmail=you@example.com
```

## Verify

```bash
az consumption budget show --budget-name az900-lab05-monthly-budget --query "{amount:amount, notifications:notifications}" -o json
```

In the portal: **Cost Management + Billing → Cost Management → Budgets**.

## Clean up

```bash
az consumption budget delete --budget-name az900-lab05-monthly-budget
```

## Lecture talking points

- **A budget is a smoke alarm, not a circuit breaker.** This is the single most important thing to land in this lab: an Azure Budget notifies, it does not stop spend or shut anything down. Automatically disabling resources at a threshold requires wiring the budget's action group to something else (an Automation runbook, a Logic App) — that's out of scope for AZ-900 but worth a one-sentence mention so students aren't surprised in the real world.
- **Actual vs Forecasted thresholds** are genuinely different mechanisms: *Actual* compares real spend-to-date against the threshold; *Forecasted* extrapolates the current trend to predict whether you'll cross 100% by period end, and can fire well before you've spent anything close to the limit. This distinction shows up on the exam.
- **Budgets are additive to — not a replacement for — the Pricing Calculator and TCO Calculator.** Tie this back to Module 6: the Pricing Calculator estimates cost *before* you deploy; the budget monitors actual cost *after*. Different tools, different moments in the lifecycle.
- **Scope matters:** this lab creates a subscription-scoped budget, but budgets can also be created at the resource group or management group level (via the Cost Management API/portal) — subscription scope is what AZ-900's objectives explicitly reference.
- **Why deploy this at subscription scope in Bicep** — same `targetScope` concept as Lab 1, reinforcing that not everything lives inside a resource group.

## What you learned

By completing this lab, you can now:

- Explain why a budget is a notification mechanism, not a spending cap, and describe what it would take to make it actually stop spend (wiring the action group to an Automation runbook or Logic App).
- Distinguish an Actual threshold from a Forecasted threshold, and describe a scenario where each would fire at a different point in the billing period.
- Place budgets correctly relative to the Pricing Calculator: the calculator estimates cost *before* deployment, a budget monitors real cost *after* deployment.
- State that budgets can be scoped above or below subscription level (resource group or management group), even though this lab deploys one at subscription scope.
- Locate and read a budget's configuration and notification thresholds in **Cost Management + Billing → Budgets**.
