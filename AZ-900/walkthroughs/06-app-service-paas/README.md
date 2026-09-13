# Walkthrough — App Service / PaaS (Lab 6)

A guided, portal-first walkthrough of what [Lab 6](../../labs/06-app-service-paas/) deploys. The lab's own README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for actually seeing PaaS's managed layer in the portal: what's configurable, and what's greyed out on purpose.

**Prerequisite:** Lab 6 is already deployed (`az deployment group create ...` from the lab README).

## Part 1 — Visit the live app

1. Open `rg-az900-lab06` → your web app → **Overview**, and click the **Default domain** link (or copy it into a browser).
2. You'll land on the default "your app is running" placeholder page — confirming a live, publicly reachable web app exists, with no code deployed and nothing configured beyond what this lab's template set.

## Part 2 — Find the App Service Plan and what it actually controls

1. Still on the web app's **Overview**, find and click the **App Service Plan** link (it'll be named something like `asp-<your-webapp-name>`).
2. On the Plan's own Overview, note the **Pricing tier** (F1) and that this is the resource actually being billed and scaled — the web app itself is just code running on top of it.
3. If you had deployed a second web app using the same plan name, it would show up here too, sharing this same plan's capacity for free (up to F1's limits) — worth saying even though this lab only deploys one.

## Part 3 — Find the F1 tier's limits, visible as disabled controls

1. Back on the web app, go to **Settings → Configuration → General settings**.
2. Find **Always On** and try to toggle it — it's disabled/greyed out. This isn't a bug; F1 (Free) doesn't support Always On at all, which is exactly why the app "cold starts" after being idle for a while. Seeing the control disabled is more convincing than reading about the limit.
3. Look for **Platform settings** or plan details mentioning the daily CPU-minute quota (60 minutes/day on F1) — another hard limit worth locating once, not just remembering as a fact.

## Part 4 — Confirm the managed runtime stack

1. Still in **Configuration → General settings**, find the **Stack settings** section.
2. Confirm it shows the Node.js runtime version (matching `linuxFxVersion: 'NODE|20-lts'` from the Bicep template) — this is Azure managing the language runtime and OS patching for you, the exact PaaS trait this lab exists to demonstrate.

## Part 5 — Confirm HTTPS-only is actually enforced

1. Go to **Settings → TLS/SSL settings**.
2. Confirm **HTTPS Only** is set to **On** — matching `httpsOnly: true` in the template.
3. If you're comfortable with a quick test: try loading the app's URL with `http://` instead of `https://` in the browser — it redirects to HTTPS automatically rather than serving plain-text traffic.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Distinguish the App Service Plan from the Web App** in the portal, and explain which one is the unit of billing/scale and which one is just the code running on it.
- **Point to a specific disabled control (Always On) as proof of a pricing-tier limit**, rather than only reciting that F1 has limits.
- **Locate the managed runtime stack setting** and connect it directly to what PaaS means: Azure owns the OS and runtime patching, you own the app and its configuration.
- **Confirm HTTPS enforcement is active**, not just declared in a template, by observing the plain-HTTP-to-HTTPS redirect yourself.
