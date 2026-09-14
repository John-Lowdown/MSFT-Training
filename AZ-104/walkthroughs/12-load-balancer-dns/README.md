# Walkthrough — Standard Load Balancer & Azure DNS (Lab 12)

A guided, portal-first walkthrough of what [Lab 12](../../labs/12-load-balancer-dns/) deploys. The lab README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for tracing one request through the Load Balancer's own blades afterward, so "backend pool," "health probe," and "outbound rule" stop being separate vocabulary words and become pieces of one mechanism you've traced end to end.

**Prerequisite:** Lab 12 is already deployed (`az deployment group create ...` from the lab README) and you have the resource group open in the [Azure Portal](https://portal.azure.com).

## Part 1 — Trace one request path through three blades

1. Open `rg-az104-lab12` and click into `lb-az104lab12`.
2. Select **Frontend IP configuration** in the left menu — one entry, `feConfig`, using `pip-az104lab12-lb`. This is where a request arrives.
3. Select **Backend pools** — one entry, `beAddressPool`. Open it; it's empty in this lab (no VMs deployed), which is expected — the pool, rule, and probe are all real and correctly wired even with nothing registered in the pool yet.
4. Select **Health probes** — `httpProbe`, protocol TCP, port 80, checking every 5 seconds. This is what would decide, if the pool had members, which of them actually receive traffic.
5. Select **Load balancing rules** — `lbRuleHttp`. Open it and look at how it references all three pieces you just saw: the frontend IP from step 2, the backend pool from step 3, and the probe from step 4. This rule is the thing that ties a request arriving at the frontend to where it's allowed to go and under what health condition.

That's the full path: frontend → rule → probe-gated backend pool. Walk it in that order out loud — it's the same order the portal's own blades are listed in.

## Part 2 — The outbound rule, specifically

1. Still on `lb-az104lab12`, select **Outbound rules** in the left menu.
2. Open `outboundRuleDefault`. Notice it references the same frontend IP and backend pool as the load-balancing rule in Part 1, but it's a **separate rule object** governing a different direction of traffic — backend instances reaching *out* to the internet, not requests coming *in*.
3. This is the point worth making explicit: if this rule didn't exist, any VM placed in `beAddressPool` would have **no outbound internet access at all** under the Standard SKU. Basic SKU gave that access implicitly; Standard does not. Nothing in the portal would "look broken" — the VM would just silently have no way out, which is a confusing thing to debug the first time you hit it.

## Part 3 — The DNS zone

1. In the portal search bar, find `az104lab12-demo.com` (an Azure DNS zone).
2. On its **Overview** page, look at the record sets Azure generated automatically: an **NS** record (the name servers Azure assigned this zone) and an **SOA** record. You wrote neither of these — Azure creates them the moment the zone exists.
3. Find the **A** record named `www`. Open it and confirm its value matches the load balancer's public IP from Part 1's frontend configuration.
4. Point out what this zone is *not* doing: resolving on the public internet. That only happens once this domain's registrar is told to use the NS records from step 2 — an optional step this lab never requires, because the record-management mechanics you just walked through are the actual exam content, independent of a live domain.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Trace a single request path** through a Standard Load Balancer's frontend IP, load-balancing rule, health probe, and backend pool, in that order.
- **Locate the Outbound rules blade specifically** and explain why it's a distinct object from the inbound load-balancing rule, even though both reference the same frontend and pool.
- **State the concrete symptom of a missing outbound rule** on Standard SKU — no internet access for backend instances, with nothing in the configuration visibly "broken."
- **Read a DNS zone's auto-generated NS and SOA records** and distinguish them from the A record you created yourself.
- **Explain what domain delegation would add** on top of a zone's already-real, already-testable record-management mechanics.
