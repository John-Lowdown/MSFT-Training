# Walkthrough — RBAC Role Assignment (Lab 4)

A guided, portal-first walkthrough of what [Lab 4](../../labs/04-rbac-role-assignment/) deploys. The lab's own README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for reading the assignment's anatomy in the portal, and surfacing a genuinely non-obvious gotcha: why you probably won't feel any different after being granted Reader.

**Prerequisite:** Lab 4 is already deployed (`az deployment group create ...` from the lab README).

## Part 1 — Find your role assignment

1. Open `rg-az900-lab04` and go to **Access control (IAM)** in the left menu.
2. Click the **Role assignments** tab. Find your own name (or the principal you assigned) listed with the **Reader** role.
3. Click **View** (or the row itself, depending on portal version) to see the same three ingredients from the lab's talking points laid out as an actual record: **Security principal**, **Role**, and **Scope** — this exact resource group.

## Part 2 — Use "Check access" to ask the question directly

1. Still on the **Access control (IAM)** page, click the **Check access** tab.
2. Search for your own account and select it.
3. Azure shows you every role assignment that applies here, including ones inherited from above (subscription or management group level) — not just the Reader role this lab added. This is the portal literally answering "can this identity do this, at this scope?" — the exact question RBAC exists to answer.

## Part 3 — The gotcha: why nothing feels different

1. Try to create a new resource inside `rg-az900-lab04` — you'll almost certainly succeed, even though you just gave yourself only Reader here.
2. This isn't a bug in the lab. RBAC is **additive**: if you already hold Owner or Contributor at the subscription level (which you likely do, since it's your own subscription), that higher-scope permission still applies here too. Adding a lower-privilege role at a narrower scope never takes anything away.
3. To actually see Reader-only behavior enforced, you'd need to test as a *different* identity that has no higher-scope role — a colleague's account, a service principal, or a guest user with nothing else assigned. Worth stating this limitation out loud rather than letting students assume the lab "didn't work" if they don't feel restricted.

## Part 4 — See inheritance from above, not just this lab's assignment

1. Go to your **Subscription** → **Access control (IAM)** → **Role assignments**.
2. Find whatever role you hold at the subscription level (likely Owner).
3. Go back to `rg-az900-lab04`'s own Role assignments tab — that subscription-level role shows up here too, in a **Scope** column reading something like "(Inherited)". This is the same downward-inheritance principle from the lab's talking points, visible as a real row in a real list instead of a diagram.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Read a role assignment's three components** (security principal, role, scope) directly from the Access control (IAM) blade instead of only from a Bicep parameter list.
- **Use "Check access"** to answer "can this identity do this, here?" for any principal at any scope.
- **Explain why RBAC being additive means a lower-scope role assignment can be invisible in practice** — a genuinely common point of confusion this walkthrough deliberately surfaces rather than leaving until an exam question does.
- **Identify an inherited role assignment** in a resource group's Role assignments list and trace it back to the higher scope (subscription or management group) where it was actually granted.
