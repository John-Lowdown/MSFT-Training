# Walkthrough — Virtual Network & NSGs (Lab 3)

A guided, portal-first walkthrough of what [Lab 3](../../labs/03-vnet-nsg/) deploys. The lab's own README covers the Bicep deploy/verify/cleanup commands and the CLI-based rule inspection — this walkthrough is for reading the same configuration in the portal, including the default rules that exist even though nobody wrote them.

**Prerequisite:** Lab 3 is already deployed (`az deployment group create ...` from the lab README).

## Part 1 — Tour the VNet and its two subnets

1. Open `rg-az900-lab03` and click into `vnet-az900-lab03`.
2. Go to **Settings → Subnets** — you'll see `snet-web` (10.20.1.0/24) and `snet-data` (10.20.2.0/24), each with a different NSG attached in the **Network security group** column.

## Part 2 — Read the data subnet's NSG rules

1. Open `nsg-az900-lab03-data` and go to **Settings → Inbound security rules**.
2. You'll see exactly one custom rule: allow SQL (1433) from the web subnet's address range. Nothing from the internet at all.
3. Toggle **Show default rules** (or scroll down, depending on portal version) to reveal the rules nobody wrote: `AllowVnetInBound`, `AllowAzureLoadBalancerInBound`, `DenyAllInBound`, and their outbound equivalents. These exist on every NSG whether or not you configure anything — worth reading through once so they stop being invisible.

## Part 3 — Compare against the web subnet's NSG

1. Open `nsg-az900-lab03-web` and its **Inbound security rules**.
2. Confirm the one custom rule here is the opposite shape: allow HTTPS (443) from `Internet` — the public-facing side of the same two-tier pattern.
3. Notice both NSGs share the same default rules from Part 2 — those aren't specific to one NSG, they're baked into every NSG Azure creates.

## Part 4 — See the priority-and-first-match model directly

1. On either NSG's **Inbound security rules** blade, look at the **Priority** column — your custom rule sits at `100`, well below the default rules (typically in the 65000s).
2. This is the mechanic, not just the theory: Azure evaluates rules in ascending priority order and stops at the first match. A lower number always wins a conflict, which is why your custom rule at `100` takes effect before Azure ever reaches its own defaults at `65000+`.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Locate which NSG is attached to which subnet** in the VNet's Subnets blade, and read a specific NSG's inbound rules.
- **Point to the default rules Azure adds automatically** (`AllowVnetInBound`, `AllowAzureLoadBalancerInBound`, `DenyAllInBound`) instead of only knowing they exist in the abstract.
- **Explain the priority-and-first-match evaluation model** using the actual priority numbers visible in the portal, not just the rule of thumb.
- **Describe the two-tier segmentation pattern** this lab builds — a public-facing subnet and a data subnet that only trusts traffic from the web tier — and why nothing here reaches the data subnet directly from the internet.
