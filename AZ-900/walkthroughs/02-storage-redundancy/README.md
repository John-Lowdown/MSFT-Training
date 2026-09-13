# Walkthrough — Storage Redundancy (Lab 2)

A guided, portal-first walkthrough of what [Lab 2](../../labs/02-storage-redundancy/) deploys. The lab's own README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for actually seeing the LRS/ZRS/GRS distinction in the portal, including the one detail that catches people out on the exam: what "readable" really means for a GRS secondary region.

**Prerequisite:** Lab 2 is already deployed (`az deployment group create ...` from the lab README).

## Part 1 — Compare all three accounts side by side

1. Open `rg-az900-lab02` and you'll see three storage accounts: one ending `lrs`, one `zrs`, one `grs`.
2. Open each in turn and go to **Data protection → Redundancy** in the left menu.
3. Confirm the **Redundancy** dropdown shows the matching SKU for each — this is the single setting that determines everything else in this walkthrough.

## Part 2 — Find the GRS account's paired region

1. On the `grs` account's **Redundancy** blade, look for the secondary region Azure has paired with your primary (for example, if you deployed to East US, the pair is typically West US, or Central US pairs with East US 2 — the exact pairing depends on your primary region).
2. This is the "region pair" concept from the core architecture module made concrete: you didn't choose this secondary region, Microsoft assigned it, and it only becomes relevant during an actual disaster-recovery failover.

## Part 3 — Confirm the exam trap directly: the secondary copy isn't readable yet

1. Still on the `grs` account's **Redundancy** blade, look for the checkbox labeled something like *"Make read access to data available in the event of regional unavailability"* (the RA-GRS toggle).
2. It's **unchecked** — because this lab deploys plain `Standard_GRS`, not `Standard_RA-GRS`. That checkbox being off, visible right there in the portal, is the literal answer to the exam's favorite GRS distractor: the secondary copy exists, but nothing can read it until an actual failover happens.
3. If you want to see the alternative, don't check this box on the deployed lab account — instead, note that checking it (or deploying with `Standard_RA-GRS` from the start) is what would enable a live, always-on read endpoint in the secondary region.

## Part 4 — Confirm the free security settings while you're here

1. On any of the three accounts, go to **Settings → Configuration**.
2. Confirm **Minimum TLS version** is set to `1.2` and **Secure transfer required** (HTTPS-only) is `Enabled` — both set explicitly in the Bicep template, at no extra cost, as a quiet callback to Module 5's security content.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Read a storage account's redundancy SKU** directly in the portal and connect it to the LRS/ZRS/GRS distinctions from the lab's talking points.
- **Locate a GRS account's paired secondary region** and explain that Azure — not the customer — chooses that pairing.
- **Point at the exact portal control that answers the GRS-vs-RA-GRS exam trap** — the read-access checkbox — rather than only reciting the distinction from memory.
- **Confirm a storage account's transport security settings** (minimum TLS version, HTTPS-only) and connect them to the shared responsibility model's customer-owned configuration layer.
