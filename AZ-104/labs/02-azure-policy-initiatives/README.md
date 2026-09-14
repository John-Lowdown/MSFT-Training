# Lab 02 — Azure Policy: Initiatives & Remediation

**AZ-104 domain:** Manage Azure identities and governance (20–25%) — Implement and manage Azure Policy
**Cost:** $0 — policy definitions, initiatives, assignments, and remediation tasks carry no charge
**Time:** ~25 minutes (allow extra time for the remediation task to run — see below)

## What you'll build

A custom **Modify**-effect policy that auto-appends a `costCenter` tag to resource groups missing one, grouped with the built-in "Require a tag on resource groups" policy into a **policy initiative**, assigned with a **system-assigned managed identity**, plus a **remediation task** that fixes resource groups that existed *before* the policy was assigned. AZ-900 Lab 8 stopped at a single Deny policy; this lab goes one level deeper into the machinery real organizations actually run — grouped policies, write-capable effects, and cleanup of pre-existing non-compliance.

## Deploy

```bash
az deployment sub create \
  --location eastus \
  --template-file main.bicep
```

## Verify

```bash
az policy definition show --name az104-lab02-modify-costcenter-tag -o table
az policy set-definition show --name az104-lab02-tagging-initiative -o table
az policy assignment show --name az104-lab02-assignment --resource-group rg-az104-lab02 -o table

az policy remediation show \
  --name az104-lab02-remediation \
  --resource-group rg-az104-lab02 \
  --query "{name:name, provisioningState:properties.provisioningState, resourceCount:properties.resourceCount}" -o json
```

In the portal: **Policy → Definitions** (search "AZ-104 Lab 02") for both policies, **Policy → Definitions → Initiative definitions** for the grouped initiative, **Policy → Assignments** for the assignment and its managed identity, and **Policy → Remediation** for the task's run history.

Remediation tasks don't run instantly — give it a few minutes, then re-check `provisioningState` until it reads `Succeeded`. Once it has, `rg-az104-lab02` should carry a `costCenter` tag it didn't have before the policy touched it.

## Clean up

Deletion order matters and mirrors AZ-900 Lab 8's "assignment before definition" rule, just one level deeper — the initiative sits between the assignment and the individual policy:

```bash
# Optional tidiness step — not strictly required before the rest
az policy remediation delete --name az104-lab02-remediation --resource-group rg-az104-lab02

az policy assignment delete --name az104-lab02-assignment --resource-group rg-az104-lab02
az policy set-definition delete --name az104-lab02-tagging-initiative
az policy definition delete --name az104-lab02-modify-costcenter-tag

az group delete --name rg-az104-lab02 --yes --no-wait
```

## Lecture talking points

- **Initiatives exist because nobody assigns policies one at a time in a real tenant.** A real compliance framework (e.g. a regulatory baseline, an internal security standard) is dozens of individual policies — grouping them into one initiative means one assignment, one managed identity, one compliance score, instead of managing each policy's lifecycle separately.
- **Why Modify needs a managed identity and Deny never did.** Deny and Audit only *evaluate* a request and either block it or flag it — they never write anything, so they need no identity of their own. Modify and DeployIfNotExists actually change or create resources on the policy's behalf, which means the assignment needs a `SystemAssigned` identity holding real write permissions (here, Tag Contributor) at the scope it will act on.
- **Remediation tasks only matter for effects that act after the fact.** Deny already stopped the problem at creation time — there's nothing left to remediate. Modify, DeployIfNotExists, and AuditIfNotExists can all leave pre-existing resources non-compliant, because the policy only started evaluating the moment it was assigned; a remediation task is what goes back and fixes what was already there.
- **Direct callback to AZ-900 Lab 8.** "Last course, you saw Deny block a bad deployment outright. This course, you see why Deny alone doesn't help with resources that already existed before the policy existed — that's what Modify plus a remediation task is for."
- **`mode: 'All'`, not `'Indexed'`, because this policy targets resource groups.** `Indexed` mode only evaluates resource types that support tags and location — and specifically skips resource groups and subscriptions, even though resource groups themselves carry tags. Any policy whose `if` condition checks `type equals 'Microsoft.Resources/subscriptions/resourceGroups'` needs `All` mode or it silently never fires. This is close to an AZ-900 Lab 8 callback in reverse: that lab's policy targeted a resource type and used `Indexed`; this one targets the container above it and needs `All`.
- **`roleDefinitionIds` on the policy definition, not the assignment.** Students sometimes expect the managed identity's permissions to be configured where the identity is created (the assignment); the policy definition itself declares which roles any assignment's identity will need, and Azure grants them automatically when the assignment is created with an identity.
- **Initiative compliance reporting and individual policy compliance reporting are the same screen, different grouping.** Policy → Compliance can show results per-initiative or drilled down to the individual policy inside it — worth a one-sentence mention so students don't think initiatives hide the underlying per-policy detail.

## What you learned

By completing this lab, you can now:

- Explain why organizations group related policies into an **initiative** instead of managing dozens of individual assignments.
- Write a custom **Modify**-effect policy and identify why it requires `roleDefinitionIds` that Deny/Audit policies never need.
- Assign an initiative with a **system-assigned managed identity** and grant that identity the permissions its policies need to remediate.
- Create and monitor a **remediation task**, and explain which policy effects need one (Modify, DeployIfNotExists, AuditIfNotExists) versus which never do (Deny).
- Delete policy resources in the correct dependency order: assignment, then initiative, then individual policy definitions.
