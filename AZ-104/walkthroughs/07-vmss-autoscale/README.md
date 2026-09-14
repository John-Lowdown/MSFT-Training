# Walkthrough — VM Scale Sets & Custom Autoscale (Lab 07)

A guided, portal-first walkthrough of what [Lab 07](../../labs/07-vmss-autoscale/) deploys. The lab README covers the Bicep deploy/verify/cleanup commands — this walkthrough is for reading the autoscale configuration in the portal so its pieces (metric, rule, capacity range) stop being abstract and become things you've actually clicked through on a real scale set.

**Prerequisite:** Lab 07 is already deployed (`az deployment group create ...` from the lab README) and you have the resource group open in the [Azure Portal](https://portal.azure.com).

## Part 1 — Confirm the orchestration mode and current instance count

1. Open your resource group (`rg-az104-lab07`) and click into **vmss-az104lab07**.
2. On **Overview**, note the **Orchestration mode** shown as **Flexible**.
3. In the left-hand menu, select **Instances**. You should see exactly 1 running instance — the `defaultCapacity` this lab deployed with.

## Part 2 — Read the custom autoscale rules

1. In the left-hand menu, under **Settings**, select **Scaling**.
2. Confirm the mode toggle at the top is set to **Custom autoscale**, not "Manual scale" — Manual scale would mean no rules are active at all.
3. Under the default profile, look at the **Instance limits**: Minimum `1`, Maximum `3`, Default `1` — this is the capacity range, separate from the rules below it.
4. Scroll to the **Rules** list. You should see two:
   - **Increase count by 1** when **Percentage CPU** > 70 (average, over 5 minutes)
   - **Decrease count by 1** when **Percentage CPU** < 30 (average, over 5 minutes)
5. Click into either rule to see its **Cooldown** (5 minutes) — the pause autoscale enforces before evaluating and acting on that rule again.

Notice these are genuinely two separate rule objects, not one rule with a range — that's the pairing this lab's lecture notes call out as a common thing to miss.

## Part 3 — Look at the actual CPU metric (and why it won't fire today)

1. Still in the scale set, go to **Monitoring → Metrics**.
2. Add the metric **Percentage CPU**, aggregation **Average**.
3. You'll see a mostly idle line, nowhere near the 70% scale-out threshold — this is an idle B1s instance from a short lab session, not a loaded production workload.

Say this part out loud: the rule is correctly configured and would genuinely fire on sustained real load, but a short classroom demo isn't going to organically produce that load. That's fine — the teaching goal is reading the rule's anatomy, not watching a live scale event.

## Part 4 — (Optional) Trigger a scale-out and watch Instances change

If you ran the `az vmss run-command invoke` load-generation command from the lab README's manual tasks against an instance:

1. Give it several minutes — the metric has to average above 70% for the full 5-minute window before the rule evaluates true, plus up to another minute for the next evaluation cycle.
2. Watch the **Instances** blade; a second instance should appear once the rule fires.
3. After the load script finishes (or you stop it), give it more time and watch the **Decrease** rule eventually bring the count back down — subject to its own 5-minute window and cooldown.

This step is genuinely optional and can take 10+ minutes to show anything — don't block the rest of the walkthrough on it.

## Part 5 — Tour the network configuration

1. Go to **Settings → Networking**.
2. Confirm the scale set's instances sit in `snet-vmss` inside `vnet-az104lab07`, with no public IP attached to any instance — consistent with this lab's design, since the only access path used here is `az vmss run-command invoke`, which doesn't need one.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Confirm a scale set's orchestration mode** (Flexible vs. Uniform) directly from its Overview page.
- **Read a custom autoscale configuration end to end**: capacity range, and each rule's metric, threshold, direction, and cooldown.
- **Explain why a capacity range and a scaling rule are two separate configuration layers**, not one combined setting.
- **Distinguish a correctly-configured autoscale rule from one that has actually fired**, and explain why a short demo session is unlikely to generate enough real load to trigger one organically.
- **Locate where scale set instances run network-wise** even when no instance has a public IP, and explain why `run-command invoke` doesn't need one.
