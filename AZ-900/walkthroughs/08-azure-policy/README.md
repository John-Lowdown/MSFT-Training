# Walkthrough — Azure Policy (Lab 8)

A guided, portal-first walkthrough of what [Lab 8](../../labs/08-azure-policy/) deploys. The lab's own README covers the Bicep deploy and the CLI-based denied-deployment demo — this walkthrough is for reading the policy's anatomy in the portal and watching its compliance view populate over time.

**Prerequisite:** Lab 8 is already deployed (`az deployment sub create ...` from the lab README).

## Part 1 — Read the policy definition

1. In the portal search bar, go to **Policy**.
2. Click **Definitions** in the left menu, then search for "AZ-900 Lab 8."
3. Open it and look at the **JSON view** (top toolbar) to see the raw `policyRule` — the same `if`/`then` block from the Bicep template, now shown as Azure Policy actually stores it.
4. Notice the **Category** is "Custom" — this distinguishes it from the hundreds of built-in policies Microsoft ships (things like "Storage accounts should disallow public network access"), which you'll see listed alongside it if you clear the search filter.

## Part 2 — Read the assignment

1. Click **Assignments** in the left menu and open `az900-lab08-assignment`.
2. Under **Parameters**, confirm `effect` is set to whatever you deployed with (`Deny` by default).
3. Under **Scope**, confirm it's assigned at your subscription — not a specific resource group. This is deliberate: the point of this lab is that Policy typically governs broadly, not resource-by-resource.

## Part 3 — Watch the deny happen, then find it in the portal

1. Run the denied-deployment demo from the [lab README](../../labs/08-azure-policy/README.md#watch-it-deny-a-real-deployment) if you haven't already.
2. Back in the portal, on the assignment's page, click the **Compliance** tab.
3. Immediately after a deny, this tab may still show "Not started" or no data — compliance *scanning* is a separate, slower process from the *synchronous* deny that already happened at deployment time. This is worth sitting with: the enforcement was instant, but the reporting lags behind it.
4. Check back in 15–30 minutes and refresh — you should see the policy's compliance state populate, and if any pre-existing non-compliant storage accounts exist in your subscription, they'll show up here too (this policy evaluates everything in scope, not just new deployments).

## Part 4 — Try the Audit effect

1. Redeploy the lab with `--parameters policyEffect=Audit`.
2. Attempt the same denied-deployment demo again — this time it **succeeds**. The storage account gets created with public blob access enabled.
3. Wait for a compliance scan (or trigger one manually: **Policy → Compliance → your assignment → Trigger evaluation scan** in some portal versions, or `az policy state trigger-scan`) and confirm the same storage account now shows up as **non-compliant** in the Compliance tab.
4. This is the real-world sequencing point from the lab's talking points made visible: organizations roll out `Audit` first to see what *would* have been blocked, then flip to `Deny` once they trust the policy isn't going to break something they didn't anticipate.

## Clean up

Same as the lab's own cleanup — delete the assignment, then the definition, then any demo resource groups. See the [lab README](../../labs/08-azure-policy/README.md#clean-up).

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Read a policy definition's JSON directly in the portal** and connect its `if`/`then` structure back to the Bicep source that created it.
- **Distinguish enforcement from reporting** — a deny happens synchronously at deployment time; compliance scanning that reflects it in the portal happens on a separate, slower schedule.
- **Explain why `Audit` typically comes before `Deny`** in a real governance rollout, having actually seen a non-compliant resource get created under `Audit` and flagged afterward, rather than blocked outright.
- **Locate both custom and built-in policies** in the same Definitions list, and describe what distinguishes a custom policy (like this lab's) from Microsoft's built-in library.
- **State the scope this policy was assigned at** (subscription) and why that's a deliberate governance choice, not an accident of where the lab happened to deploy.
