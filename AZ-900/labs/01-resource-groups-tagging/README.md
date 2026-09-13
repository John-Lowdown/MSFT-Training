# Lab 1 — Resource Groups & Tagging

**AZ-900 domain:** Cloud Concepts / Governance
**Cost:** $0 — resource groups themselves are free
**Time:** ~10 minutes

## What you'll build
A resource group with a standard tag set (`environment`, `costCenter`, `course`, `lab`, `managedBy`), deployed at **subscription scope** — the first thing you'll notice is that this template doesn't target a resource group, it creates one.

## Deploy

```bash
az login
az account set --subscription "<your-subscription-name-or-id>"

az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters resourceGroupName=rg-az900-lab01 environment=dev costCenter=IT-Training
```

## Verify

```bash
az group show --name rg-az900-lab01 --query "{name:name, location:location, tags:tags}" -o table
```

You should see all five tags applied. In the portal: **Resource groups → rg-az900-lab01 → Tags**.

## Clean up

```bash
az group delete --name rg-az900-lab01 --yes --no-wait
```

## Lecture talking points

- **Resource groups are a management boundary, not a billing boundary or a network boundary.** Resources in different regions can live in the same resource group; the resource group itself has a location only because *some* metadata about the group (like deployment history) has to live somewhere.
- **Tags are inherited by nothing.** A tag on a resource group does not automatically appear on the resources inside it — that's a common exam trap. If students want tag inheritance, that's an Azure Policy job (`modify` effect), not a resource-group feature.
- **Why tag at all?** Cost allocation (tie spend to `costCenter`), automation targeting (scripts that act on everything tagged `environment=dev`), and governance reporting. This is a direct lead-in to Module 5 (governance/compliance) and Module 6 (cost management) later in the course.
- **`targetScope = 'subscription'`** is worth pausing on — most students' first bicep file targets a resource group implicitly. This is their first look at deployment scopes (resource group / subscription / management group / tenant), which shows up again in Lab 4 (RBAC) and is directly testable on the exam.
- **Idempotency:** re-running this deployment is safe — Bicep/ARM will no-op if nothing changed, which is a good moment to demo `az deployment sub create --what-if`.

## What you learned

By completing this lab, you can now:

- Explain why a resource group is a management and lifecycle boundary — not a billing boundary or a network boundary.
- State that tags on a resource group are **not** automatically inherited by the resources inside it, and why that's a commonly tested exam trap.
- Describe at least two real reasons to tag resources beyond "organization": cost allocation (tie spend to a `costCenter`) and automation targeting (scripts acting on everything tagged `environment=dev`).
- Identify `targetScope = 'subscription'` in a Bicep file and explain why creating a resource group itself is a subscription-level operation.
- Demonstrate idempotency by re-running this deployment and observing that Bicep/ARM safely no-ops when nothing has changed.
