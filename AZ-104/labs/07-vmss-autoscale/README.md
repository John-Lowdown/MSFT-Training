# Lab 07 — VM Scale Sets & Custom Autoscale

**AZ-104 domain:** Deploy and manage Azure compute resources (20–25%) — Deploy and configure Azure Virtual Machine Scale Sets
**Cost:** REAL, and it scales with instance count — same per-instance hourly cost as [Lab 06](../06-vm-availability-disks/) (`Standard_B1s`), multiplied by however many instances autoscale spins up. Default capacity is 1 to keep this cheap. Delete promptly.
**Time:** ~25 minutes

## What you'll build

A **Flexible-orchestration VM Scale Set** running `Standard_B1s` instances (starting at 1), paired with a **custom autoscale** setting that watches average CPU and scales out above 70% / scales in below 30%, bounded between 1 and 3 instances. The point of this lab isn't watching it fire live — it's being able to read an autoscale rule's anatomy cold: metric, condition, action, cooldown, and the capacity range that bounds all of it.

You'll need an SSH key pair (reuse the one from Lab 06 if you still have it):

```bash
ssh-keygen -t ed25519 -C "az104-lab07" -f ~/.ssh/id_ed25519 -N ""
```

## Deploy

```bash
az group create --name rg-az104-lab07 --location eastus

az deployment group create \
  --resource-group rg-az104-lab07 \
  --template-file main.bicep \
  --parameters adminPublicKey="$(cat ~/.ssh/id_ed25519.pub)"
```

## Verify

```bash
az vmss list-instances --resource-group rg-az104-lab07 --name vmss-az104lab07 -o table

az monitor autoscale show --resource-group rg-az104-lab07 --name as-az104lab07 \
  --query "{enabled:enabled, profiles:profiles[0].capacity}" -o json
```

In the portal: **rg-az104-lab07 → vmss-az104lab07 → Scaling** to see the custom autoscale rules side by side, and **Instances** to see the currently running instance count.

## Manual tasks (can't be done by Bicep)

1. **Watching it actually fire is impractical in a short demo.** Generating enough sustained CPU load on a `Standard_B1s` instance to realistically cross the 70% threshold and hold it for the 5-minute window isn't something you can reliably do by accident, and it's not the point of this lab. If you want to try it anyway:
   ```bash
   az vmss list-instances --resource-group rg-az104-lab07 --name vmss-az104lab07 -o tsv --query "[].instanceId"
   az vmss run-command invoke --resource-group rg-az104-lab07 --name vmss-az104lab07 \
     --instance-id <instance-id> --command-id RunShellScript \
     --scripts "yes > /dev/null & sleep 600; kill %1"
   ```
   This runs entirely through the VM agent channel — no public IP or SSH access needed. The main point of the lab is reading and understanding the rule's anatomy, not watching a scale-out event.

## Clean up

Delete the autoscale setting first, as good practice — it's not the dependent resource Azure would block on, but removing the thing most likely to keep acting on your behalf before tearing down what it's acting on is the habit worth reinforcing:

```bash
az monitor autoscale delete --resource-group rg-az104-lab07 --name as-az104lab07

az group delete --name rg-az104-lab07 --yes --no-wait
```

## Lecture talking points

- **Flexible vs. Uniform orchestration mode, one clear paragraph.** Flexible manages each instance more like a standalone VM (its own NIC/disk lifecycle), can mix VM sizes in one scale set, and spreads instances across fault domains and zones more flexibly — it's Microsoft's current recommended default for most new scale sets. Uniform is the older, rigid, identical-instance model. Both are still exam-testable; know which one you're looking at.
- **Scale-out and scale-in are two independent rules, not one.** Configure only the scale-out rule and the scale set only ever grows toward its maximum — nothing brings it back down. They have to be deliberately paired, in opposite directions, on the same metric.
- **Cooldown periods exist to stop "flapping."** Without a cooldown, a noisy, short-lived metric spike could trigger repeated scale actions back to back. The cooldown forces a pause between actions so the scale set has time to actually feel the effect of the last one before considering another.
- **Min/max/default capacity is a separate concept from the rules.** The capacity range bounds what autoscale is *allowed* to do; the rules decide *when* it acts. Mixing these up is a common exam trap — a rule with no room left in the capacity range simply does nothing when it fires.
- **Direct callback to Lab 06.** Same VM sizing and cost-per-instance concepts as the single-VM lab — now automated, with a policy deciding how many of them exist at any given moment instead of you deciding once at deploy time.

## What you learned

By completing this lab, you can now:

- Deploy a **Flexible-orchestration** VM Scale Set and explain why Flexible is the current recommended default over Uniform.
- Read a custom autoscale rule's full anatomy: metric, aggregation, time window, threshold, direction, and cooldown.
- Explain why scale-out and scale-in must be configured as a paired set of rules, not one rule alone.
- Distinguish the capacity range (min/max/default) from the rules that trigger scaling actions within it.
- Use `az vmss run-command invoke` to run a command against scale set instances without needing direct network access to them.
