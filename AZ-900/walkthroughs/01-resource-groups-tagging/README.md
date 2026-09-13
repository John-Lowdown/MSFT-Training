# Walkthrough — Resource Groups & Tagging (Lab 1)

A guided, portal-first walkthrough of what [Lab 1](../../labs/01-resource-groups-tagging/) deploys. The lab's own README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for seeing the tagging behavior live in the portal, including the one part that's hard to appreciate from a CLI output alone: tags genuinely do not cascade.

**Prerequisite:** Lab 1 is already deployed (`az deployment sub create ...` from the lab README).

## Part 1 — Find the resource group and read its tags

1. In the portal, go to **Resource groups** and open `rg-az900-lab01`.
2. On the **Overview** page, scroll to the **Tags** section — you'll see all five: `environment`, `costCenter`, `course`, `lab`, `managedBy`.
3. Click **Tags** in the left-hand menu for the dedicated tag-management blade, where you could add, remove, or edit tags directly (don't — leave the lab's tags as deployed).

## Part 2 — Find where this deployment actually shows up

1. Search **Deployments** in the portal search bar — this shows deployments *within a resource group*. Open `rg-az900-lab01`'s own **Deployments** blade (left menu) and notice it's empty or doesn't show this deployment the way you might expect.
2. Now go to your **Subscription** → **Deployments** in the left menu. This lab's deployment is here instead, because the Bicep template deploys with `targetScope = 'subscription'` — creating a resource group is itself a subscription-level operation, so the deployment record lives at that scope, not inside the resource group it created.
3. This is worth sitting with: it's a small, easy-to-miss detail that trips people up the first time they go looking for "their" deployment in the wrong place.

## Part 3 — Prove tags don't cascade

This is the exam-tested claim from the lab's talking points, made concrete instead of just read:

1. Deploy one throwaway resource *into* the tagged resource group, without giving it any tags of its own:

   ```bash
   az storage account create \
     --name az900lab01tagtest \
     --resource-group rg-az900-lab01 \
     --sku Standard_LRS
   ```

2. Back in the portal, open that new storage account's **Tags** blade.
3. It's empty. Zero tags — despite living inside a resource group carrying five of them. Tags are metadata on the specific object you set them on, nothing more; they never cascade to what's inside.
4. Clean up the test resource immediately — it's not part of the lab itself:

   ```bash
   az storage account delete --name az900lab01tagtest --resource-group rg-az900-lab01 --yes
   ```

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Read a resource group's tags** in the portal and distinguish the Overview summary from the dedicated Tags management blade.
- **Locate a subscription-scoped deployment** in the Subscription's own Deployments blade, and explain why it doesn't appear under the resource group's Deployments blade instead.
- **Demonstrate, not just state, that tags don't cascade** — you created a resource inside a heavily-tagged resource group and watched it come out with zero tags of its own.
- **Explain why tag inheritance would require Azure Policy** (a `modify` effect, specifically) rather than being a resource-group feature — a direct forward link to Lab 8.
