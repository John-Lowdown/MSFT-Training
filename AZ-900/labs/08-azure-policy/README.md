# Lab 8 — Azure Policy

**AZ-900 domain:** Azure Management & Governance — Azure Policy
**Cost:** $0 — policy definitions and assignments carry no charge
**Time:** ~15 minutes (allow a few extra minutes for the assignment to become active — see below)

## What you'll build

A custom Azure Policy definition and a subscription-scoped assignment that **denies any storage account with public blob access enabled** — the exact example Microsoft's own AZ-900 study guide uses to contrast Azure Policy against RBAC. This is the lab that finally puts a real deployment in front of a real deny.

## Deploy

```bash
az deployment sub create \
  --location eastus \
  --template-file main.bicep
```

This deploys with `policyEffect=Deny` by default. Pass `--parameters policyEffect=Audit` instead if you'd rather flag non-compliant resources without blocking them.

## Verify

```bash
az policy definition show --name az900-lab08-deny-public-blob-access -o table
az policy assignment show --name az900-lab08-assignment -o table
```

In the portal: **Policy → Definitions** (search "AZ-900 Lab 8") and **Policy → Assignments**.

### Watch it deny a real deployment

Policy assignments typically take a few minutes to become active after deployment — Azure's policy engine caches evaluation, so don't be surprised if the very first attempt right after deploying still succeeds. Wait 5–10 minutes, then try:

```bash
az group create --name rg-az900-lab08-demo --location eastus

az storage account create \
  --name az900lab08denydemo \
  --resource-group rg-az900-lab08-demo \
  --location eastus \
  --sku Standard_LRS \
  --allow-blob-public-access true
```

Once the assignment is active, this fails with a `RequestDisallowedByPolicy` error naming your policy definition directly — a live, unmistakable demonstration that the deployment was blocked by *configuration*, not by anyone's permissions. Note what didn't matter here: your RBAC role. You could be the subscription Owner and this still fails.

If it's not denying yet, either wait a bit longer or check **Policy → Compliance** in the portal — full compliance *scanning* can take up to 30 minutes to populate even though the deny itself, once active, is enforced synchronously at deployment time.

## Clean up

Assignments must be deleted before the definition they reference:

```bash
az group delete --name rg-az900-lab08-demo --yes --no-wait
az policy assignment delete --name az900-lab08-assignment
az policy definition delete --name az900-lab08-deny-public-blob-access
```

## Lecture talking points

- **RBAC vs. Azure Policy, made concrete.** This is the single most emphasized distinction in the management-and-governance domain, and Lab 4 (RBAC) + Lab 8 (this one) are designed to be taught back-to-back: RBAC answers "can this identity perform this action, at this scope?" Policy answers "is this resource's configuration compliant, regardless of who touched it?" A subscription Owner with full RBAC permissions still gets denied here — permission to *try* isn't permission for the *result* to exist.
- **Why `mode: 'Indexed'`.** Indexed mode means the policy only evaluates resource types that support tags and location — appropriate here since we're targeting a specific resource type (`Microsoft.Storage/storageAccounts`) rather than resource groups or subscriptions themselves.
- **The policy rule language isn't Bicep.** The `if`/`then` block and the `"[parameters('effect')]"` reference look out of place next to normal Bicep syntax because they're Azure Policy's own rule language — Bicep just carries that JSON through unchanged. Worth pointing out explicitly so students don't try to "Bicep-ify" it.
- **Assignment propagation delay is a real-world gotcha, not a bug.** If a live classroom demo doesn't deny instantly, that's expected — Policy evaluation has a caching layer. This is worth naming out loud before attempting the live demo, so a slow first try doesn't look like something's broken.
- **Effect flexibility (`Deny` / `Audit` / `Disabled`) mirrors how real organizations roll out policy.** Nobody enables `Deny` on day one across a live estate — the standard practice is `Audit` first to see what would have been blocked, then `Deny` once confident. This lab defaults to `Deny` for a clear demo, but say this out loud as the responsible real-world sequence.
- **Direct callback to Lab 7's resource lock.** A lock blocks one specific action (usually delete) on one specific resource, regardless of identity. Policy blocks *creation of non-compliant configuration*, evaluated continuously, also regardless of identity. Both are "not an RBAC concept" — but they solve genuinely different problems, and conflating the two is a common exam trap.

## What you learned

By completing this lab, you can now:

- Explain the RBAC-vs-Policy distinction from direct experience, not just a comparison table: RBAC governs *who can act*, Policy governs *what's allowed to exist*.
- Read a custom Azure Policy definition's `policyRule` block and identify its condition (`if`) and its enforcement effect (`then`).
- Describe the three common policy effects (`Deny`, `Audit`, `Disabled`) and when a real organization would use each.
- Recognize that policy assignments have a propagation delay, and distinguish synchronous deployment-time enforcement from asynchronous compliance scanning.
- Explain why policy definitions live at subscription (or management group) scope even when the resources they govern live inside a resource group.
