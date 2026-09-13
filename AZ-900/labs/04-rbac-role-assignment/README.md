# Lab 4 — RBAC Role Assignment

**AZ-900 domain:** Identity, Governance, Compliance
**Cost:** $0
**Time:** ~10 minutes

## What you'll build
A single **Reader** role assignment, scoped to a resource group, granted to yourself (or any principal you choose) — enough to demonstrate the three pieces every role assignment has: a **security principal**, a **role definition**, and a **scope**.

## Deploy

```bash
az group create --name rg-az900-lab04 --location eastus

# Grab your own Azure AD object ID
MY_ID=$(az ad signed-in-user show --query id -o tsv)

az deployment group create \
  --resource-group rg-az900-lab04 \
  --template-file main.bicep \
  --parameters principalId=$MY_ID principalType=User roleToAssign=Reader
```

## Verify

```bash
az role assignment list --resource-group rg-az900-lab04 -o table
```

In the portal: **rg-az900-lab04 → Access control (IAM) → Role assignments** — you'll see yourself listed with the Reader role, scoped to just this resource group.

## Clean up

```bash
az group delete --name rg-az900-lab04 --yes --no-wait
```

(Deleting the resource group also deletes the role assignment, since it's scoped to that resource group.)

## Lecture talking points

- **The three-part model:** *who* (security principal — user, group, service principal, or managed identity) + *what* (role definition — the set of permitted actions) + *where* (scope — management group, subscription, resource group, or single resource). This exact framing is worth writing on a whiteboard; AZ-900 tests all three independently.
- **Role assignments are additive and inherited downward.** A Reader assignment at the subscription level flows down to every resource group and resource inside it. There's no "deny" role in classic RBAC (Azure does have explicit **deny assignments**, but they're an advanced/administrative feature, not something students assign directly — mention only if asked).
- **`principalType` matters more than it looks.** Azure AD replication lag means a just-created group or service principal might not resolve immediately; passing the type explicitly avoids an intermittent deployment failure that otherwise looks like a bug in the student's own template.
- **RBAC vs Azure Policy**, contrasted directly: RBAC answers "can this identity perform this action here?" Policy answers "is this resource's configuration compliant, regardless of who touched it?" Students conflate these constantly — this is a good moment to plant the distinction before Module 5 covers Policy in depth.
- **Built-in vs custom roles:** this lab uses a built-in role (Reader) by GUID. Mention that custom roles exist for anything built-ins don't cover, but AZ-900 only expects familiarity with the common built-ins (Owner, Contributor, Reader, User Access Administrator).

## What you learned

By completing this lab, you can now:

- Name the three components of every RBAC role assignment: a **security principal** (who), a **role definition** (what), and a **scope** (where).
- Explain that RBAC role assignments are additive and inherit downward — a role granted at a higher scope flows down to everything beneath it.
- State why `principalType` must be passed explicitly rather than inferred, and what real-world deployment failure that avoids.
- Distinguish RBAC from Azure Policy using this lab's own three-part model as the anchor: RBAC answers "can this identity do this, here?"
- Identify the difference between a built-in role (like Reader, used in this lab) and when a custom role would actually be needed instead.
