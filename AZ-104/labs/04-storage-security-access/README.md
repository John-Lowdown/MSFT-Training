# Lab 04 — Storage Security: SAS, Network Rules & Customer-Managed Keys

**AZ-104 domain:** Implement and manage storage (15–20%) — Configure access to storage
**Cost:** near-$0 — an empty storage account; Key Vault runs ~$0.03 per 10,000 operations, negligible for a short demo
**Time:** ~30 minutes

## What you'll build

A storage account locked down with a **network ACL** (`defaultAction: Deny` plus one allow-listed IP — yours), and its data protected at rest with a **customer-managed key (CMK)** held in a **Key Vault** with RBAC authorization and purge protection enabled. The storage account's own **system-assigned managed identity** is granted the built-in **Key Vault Crypto Service Encryption User** role on the vault so it can use the key. AZ-900 Lab 2 taught storage redundancy; this lab goes one level deeper into who and what can actually get to your data, and how.

## Deploy

```bash
MY_IP=$(curl -s https://ifconfig.me)

az group create --name rg-az104-lab04 --location eastus

az deployment group create \
  --resource-group rg-az104-lab04 \
  --template-file main.bicep \
  --parameters allowedClientIp=$MY_IP
```

> If you're behind a corporate VPN or NAT, `ifconfig.me` may return an IP your Azure traffic doesn't actually egress from. If data-plane calls in the Manual tasks section below get rejected, re-check your actual egress IP and re-run the deployment with the corrected `allowedClientIp`.

Capture the generated names — both the storage account and the vault get globally-unique names from the template, so you'll need these for every command below:

```bash
STORAGE_NAME=$(az deployment group show --resource-group rg-az104-lab04 --name main --query "properties.outputs.storageAccountName.value" -o tsv)
KEYVAULT_NAME=$(az deployment group show --resource-group rg-az104-lab04 --name main --query "properties.outputs.keyVaultName.value" -o tsv)
```

## Verify

```bash
az storage account show --name $STORAGE_NAME --resource-group rg-az104-lab04 \
  --query "networkRuleSet" -o json

az storage account show --name $STORAGE_NAME --resource-group rg-az104-lab04 \
  --query "encryption.{keySource:keySource, keyVaultUri:keyVaultProperties.keyVaultUri, keyName:keyVaultProperties.keyName}" -o json

az role assignment list --scope $(az keyvault show --name $KEYVAULT_NAME --query id -o tsv) -o table
```

In the portal: **rg-az104-lab04 → the storage account → Networking** to see the Deny default and your IP rule, and **→ Encryption** to see the customer-managed key pointing at your vault and key.

## Manual tasks (can't be done by Bicep)

These are genuine data-plane actions — there's no ARM resource for a SAS token or a key rotation event, so they have to happen via CLI or portal against the already-deployed account.

1. **Create a test container** (needed before (a) and (b) below):
   ```bash
   az storage container create --account-name $STORAGE_NAME --name demo --auth-mode login
   ```
   This call itself only succeeds because your IP is in the firewall's allow-list — network ACLs apply to data-plane operations too, not just the control-plane deployment you just ran.

2. **(a) Generate a SAS token for the container:**
   ```bash
   az storage container generate-sas \
     --account-name $STORAGE_NAME \
     --name demo \
     --permissions r \
     --expiry $(date -u -d "+1 hour" '+%Y-%m-%dT%H:%MZ') \
     --auth-mode login --as-user
   ```
   `--as-user` requests a **user-delegation SAS** — backed by your own Entra ID identity rather than the account's storage keys, and revocable by revoking your own access, not by rotating a shared key. Drop `--as-user` (and add `--account-key`) to generate a plain **account SAS** instead, and compare the two tokens: an account SAS can reach multiple services and is only as secure as the account key that signed it; a **service SAS** (scoped with `--services b` etc., key-signed) sits in between; a user-delegation SAS is the modern, most secure option because no storage account key is involved at all.

3. **(b) Create a stored access policy, then issue a SAS against it:**
   ```bash
   az storage container policy create \
     --account-name $STORAGE_NAME \
     --container-name demo \
     --name demo-read-policy \
     --permissions r \
     --expiry $(date -u -d "+7 days" '+%Y-%m-%dT%H:%MZ')

   az storage container generate-sas \
     --account-name $STORAGE_NAME \
     --name demo \
     --policy-name demo-read-policy \
     --auth-mode login --as-user
   ```
   A SAS token issued directly (step 2) can't be revoked before it expires — it's just a signed URL. A SAS issued against a **stored access policy** inherits that policy's permissions and expiry, and changing or deleting the policy immediately changes or revokes every outstanding SAS that references it. For any scenario where you might need to revoke access to many distributed tokens at once, a stored access policy is the only way to do that without rotating the underlying key.

4. **(c) Rotate the storage account's access keys:**
   ```bash
   az storage account keys renew --resource-group rg-az104-lab04 --account-name $STORAGE_NAME --key secondary
   # ... update any app/config that uses the secondary key ...
   az storage account keys renew --resource-group rg-az104-lab04 --account-name $STORAGE_NAME --key primary
   ```
   Every storage account has two keys specifically so you can rotate without downtime: rotate the **secondary** key first, point a live app's configuration at the fresh secondary key, confirm it works, *then* rotate primary. Rotating primary first while an app is still actively using it invalidates the key out from under a live connection.

## Clean up

```bash
az group delete --name rg-az104-lab04 --yes --no-wait
```

The role assignment on the vault and the container policy are deleted automatically with the resource group — no separate step needed there.

The Key Vault, however, does **not** fully disappear. Because `enablePurgeProtection` defaults to `true` in this lab's template, the vault drops into a **soft-deleted** state after the resource group delete and sits there for its full retention period (90 days) with no way to remove it early — not by you, not by an Owner, not by Microsoft support. That's the entire point of purge protection: a deliberate "no undo, even for an admin" control. The vault's name also stays reserved and unusable for a new vault during that window.

If you need the vault name back sooner (e.g. re-running this lab repeatedly in a classroom), redeploy with `enablePurgeProtection=false`, then after deleting the resource group, purge it explicitly:

```bash
az keyvault purge --name $KEYVAULT_NAME --location eastus
```

This only works when purge protection was off. If it was on, there is no early-purge command that will touch it — genuinely wait out the retention window.

## Lecture talking points

- **Network rules and SAS/RBAC are two independent, stackable layers.** A network ACL (`defaultAction: Deny` + allow-listed IPs/VNets) answers "can this request even reach the account." A SAS token, a stored access policy, or an RBAC role assignment answers "is this specific, already-arrived request authorized." Tightening one does nothing to the other — a perfectly valid SAS token is still useless from a blocked IP, and a request from an allowed IP still needs a valid credential.
- **Why enabling CMK needs a role assignment at all.** This isn't a human requesting access — it's the storage account's own **system-assigned managed identity** asking Key Vault to wrap/unwrap the encryption key on its behalf. Any resource that authenticates to another resource needs an identity and a role grant just like a person would; this lab's Bicep makes that chain explicit (storage account → system-assigned identity → role assignment on the vault → CMK encryption config).
- **Account SAS vs. service SAS vs. user-delegation SAS — a three-tier scope/security tradeoff.** Account SAS (broadest, key-signed, can span services) → service SAS (narrower, still key-signed) → user-delegation SAS (Entra-ID-backed, no storage key involved, most secure, the modern recommendation). The exam tests which tier is "most secure" and why — no shared key means no key to leak.
- **Stored access policies exist for revocation at scale.** A bare SAS token can't be revoked before it expires. A policy-backed SAS can — change or delete the policy and every token referencing it is affected immediately. This is the difference between "wait it out" and "turn it off right now."
- **Purge protection is governance aimed at admins, not attackers** — same theme as the resource lock in AZ-900 Lab 7 and Azure Policy's Deny effect in AZ-104 Lab 02. A `CanNotDelete` lock stops deletion regardless of role; purge protection stops permanent removal regardless of role. Both exist specifically to survive someone with full permissions making a bad call.
- **Key rotation order prevents downtime, not just "best practice."** Rotate secondary, repoint the app, confirm, then rotate primary — reversing that order invalidates a key a live connection still depends on.

## What you learned

By completing this lab, you can now:

- Configure a storage account's **network ACLs** to deny by default and allow only specific IPs, and explain that this is independent of identity-based access controls.
- Wire up **customer-managed key encryption** end to end: a system-assigned managed identity, a role assignment granting that identity access to a vault key, and the storage account's encryption settings pointing at the result.
- Generate and compare **account, service, and user-delegation SAS tokens**, and state which is most secure and why.
- Create a **stored access policy** and issue a SAS against it, and explain why that's the only way to revoke many outstanding tokens at once.
- Rotate storage account access keys in the correct, downtime-avoiding order.
- Explain **purge protection** as a deliberate "no undo, even for an admin" control, and what it actually means for cleanup timing.
