# Lab 05 — Storage Lifecycle, Versioning & Object Replication

**AZ-104 domain:** Implement and manage storage (15–20%) — Configure and manage storage accounts / Configure Azure Files and Blob Storage
**Cost:** near-$0 — two mostly-empty storage accounts and an unused 5 GiB file share quota
**Time:** ~30 minutes

## What you'll build

Two storage accounts — source and destination — with **blob versioning**, **change feed**, and **soft delete** enabled on both, because object replication needs versioning and change feed as prerequisites on either end. The source account carries a **lifecycle management policy** that tiers blobs under a prefix to Cool after 30 days and deletes them after 180, plus an **object replication policy** copying one container to the destination account, plus an **Azure Files share** to drive home that Files and Blob Storage are different services inside the same account. The source account also has **Microsoft Entra Kerberos (`AADKERB`) authentication** enabled for that file share, so it can hand out identity-based (rather than storage-key-based) SMB access. Lab 04 locked a single account down; this lab is about what happens to data already inside one over time.

## Deploy

```bash
az group create --name rg-az104-lab05 --location eastus

az deployment group create \
  --resource-group rg-az104-lab05 \
  --template-file main.bicep
```

Capture the generated account names — both get globally-unique names from the template:

```bash
SOURCE_NAME=$(az deployment group show --resource-group rg-az104-lab05 --name main --query "properties.outputs.sourceStorageAccountName.value" -o tsv)
DEST_NAME=$(az deployment group show --resource-group rg-az104-lab05 --name main --query "properties.outputs.destStorageAccountName.value" -o tsv)
POLICY_ID=$(az deployment group show --resource-group rg-az104-lab05 --name main --query "properties.outputs.objectReplicationPolicyId.value" -o tsv)
```

## Verify

```bash
az storage account blob-service-properties show \
  --account-name $SOURCE_NAME --resource-group rg-az104-lab05 \
  --query "{versioning:isVersioningEnabled, changeFeed:changeFeed.enabled}" -o json

az storage account management-policy show \
  --account-name $SOURCE_NAME --resource-group rg-az104-lab05 -o json

az storage account or-policy list \
  --account-name $SOURCE_NAME --resource-group rg-az104-lab05 -o json
```

In the portal: **rg-az104-lab05 → source storage account → Data management → Lifecycle management** to read the tier/delete rule, and **→ Object replication** to see the rule and its sync status.

## Manual tasks (can't be done by Bicep)

1. **Upload a test blob and don't expect the lifecycle rule to visibly act on it:**
   ```bash
   echo "test log line" > test.log
   az storage blob upload \
     --account-name $SOURCE_NAME --auth-mode login \
     --container-name lab05data --name "logs/test.log" --file test.log
   ```
   The lifecycle policy is correctly configured and will eventually tier this blob to Cool at day 30 and delete it at day 180 — but Azure evaluates lifecycle rules on its own schedule, typically about once every 24 hours, not on a timer you control. It will not visibly do anything in this session, and that's expected, not broken.

2. **Check the object replication policy's initial copy status:**
   ```bash
   az storage account show \
     --name $DEST_NAME --resource-group rg-az104-lab05 \
     --query "primaryEndpoints" -o json
   ```
   or, more usefully, check the replication status in the portal (next section) — the initial backlog copy is asynchronous and takes time roughly proportional to how much data already existed in the source container when the policy was created. With an empty container, the backlog copy should complete quickly; a real production container with years of data could take substantially longer.

3. **Overwrite, then delete, the test blob to actually watch versioning and soft delete work:**
   ```bash
   echo "updated log line" > test.log
   az storage blob upload \
     --account-name $SOURCE_NAME --auth-mode login \
     --container-name lab05data --name "logs/test.log" --file test.log --overwrite

   az storage blob delete \
     --account-name $SOURCE_NAME --auth-mode login \
     --container-name lab05data --name "logs/test.log"
   ```
   This is genuinely worth doing live — everything else in this lab is invisible in a code review, but overwrite-then-delete produces two things you can actually see in the portal: a previous **version** of the blob (from the overwrite) and a **soft-deleted** entry you can undelete (from the delete). See the walkthrough for exactly where to look.

4. **Verify the Entra Kerberos configuration took effect:**
   ```bash
   az storage account show \
     --name $SOURCE_NAME --resource-group rg-az104-lab05 \
     --query "azureFilesIdentityBasedAuthentication" -o json
   ```
   You should see `"directoryServiceOptions": "AADKERB"` in the output. Be honest with yourself about what this does and doesn't prove: it confirms the storage account is configured to accept Entra Kerberos tickets for SMB, but it does **not** mean you can mount the share from this CLI session. Actually mounting a share over Entra Kerberos requires a Windows client that's either Entra-joined or hybrid Entra-joined, and (per the comment in this lab's Bicep) an Entra identity that's been granted **Storage File Data SMB Share Contributor** or **...Reader** on the share or account. None of that is something a generic Cloud Shell or CI session can demonstrate — this lab genuinely can't take you further than confirming the configuration from here, and that's a real limitation of the scenario, not a shortcut this lab is taking.

## Clean up

Deletion order matters here, and it's not optional — Azure refuses to delete a storage account that's still referenced as the source or destination of an active object replication policy:

```bash
az storage account or-policy delete \
  --account-name $SOURCE_NAME --resource-group rg-az104-lab05 \
  --policy-id $POLICY_ID

az storage account or-policy delete \
  --account-name $DEST_NAME --resource-group rg-az104-lab05 \
  --policy-id $POLICY_ID

az group delete --name rg-az104-lab05 --yes --no-wait
```

Delete the policy from both accounts (or just the resource group afterward — but if you ever delete these storage accounts outside of a full resource-group teardown, the policy has to go first on whichever side you're deleting).

## Lecture talking points

- **Lifecycle rules run on Azure's own schedule, not yours.** This is one of the most common "why didn't it do anything yet" questions in a live classroom — the rule is correctly configured the moment it's deployed, but the evaluation pass itself happens roughly once every 24 hours, not instantly and not on-demand.
- **Versioning and change feed are prerequisites for object replication, not independent features.** You cannot stand up a replication policy between two accounts that don't both have versioning and change feed enabled — this lab's Bicep turns both on before the replication resources even appear, deliberately mirroring the real dependency order.
- **Soft delete and a resource lock protect against two different things.** Soft delete (this lab) protects against an accidental blob/container deletion — you can undelete within the retention window. A resource lock (AZ-900 Lab 7) protects against the storage account or resource group itself being deleted — full stop, no retention window, no undo, just blocked outright. Similar-sounding, genuinely different blast radii.
- **Azure Files and Blob Storage are different services that happen to share a storage account**, not the same feature under two names. The file share in this lab has zero relationship to the replication or lifecycle resources — it's included specifically so that point doesn't get lost.
- **Object replication's policy ID has to match exactly between source and destination.** This lab's Bicep handles that with a shared variable; doing this by hand (e.g. in the portal across two separate account blades) is exactly the kind of detail that's easy to get wrong, and the exam likes to test "why did this replication policy fail to deploy" scenarios.
- **The initial replication backlog copy is asynchronous and not instant**, even though this lab's empty containers make it finish fast — worth explicitly contrasting with a "real" production container that already holds years of data before a policy is ever created.
- **Identity-based (Entra) access for Azure Files is a two-layer configuration, and this lab only demonstrates the first layer.** Setting `azureFilesIdentityBasedAuthentication.directoryServiceOptions: 'AADKERB'` on the storage account enables Microsoft Entra Kerberos as an auth *option* for SMB — it doesn't grant anyone access. Actually connecting still requires an RBAC role assignment (Storage File Data SMB Share Contributor/Reader) to specific Entra users or groups, the same "identity + role grant" pattern as the CMK role assignment in Lab 04. Worth naming explicitly: this is genuinely different from storage-key-based SMB access, where knowing the key *is* the access.
- **This lab's accounts use LRS, and that's deliberate, not an oversight.** AZ-900 Lab 2 is where LRS/ZRS/GRS/GZRS redundancy tiers were built and compared hands-on — this course doesn't re-build that lab, it just keeps reusing the same LRS default everywhere the redundancy tier itself isn't the point. If you want the hands-on tier comparison again, that's the lab to revisit.

## What you learned

By completing this lab, you can now:

- Enable **blob versioning**, **change feed**, and **soft delete** on a storage account, and explain which of those are required before object replication will deploy.
- Write a **lifecycle management rule** with a blob-prefix filter that tiers to Cool and later deletes blobs based on time since modification.
- Configure an **object replication policy** between two storage accounts, including why the policy ID must match on both ends.
- Distinguish **soft delete** (protects against accidental blob/container deletion, time-limited undo) from a **resource lock** (protects against the resource itself being deleted, no undo at all).
- Explain why **lifecycle rules don't fire on demand** and why a replication policy's initial backlog copy takes time proportional to existing data volume.
- Recognize **Azure Files and Blob Storage** as distinct services that can coexist in one storage account without interacting.
- Enable **Microsoft Entra Kerberos authentication** (`AADKERB`) on a storage account for identity-based Azure Files access, and explain the separate RBAC role assignment still needed before any specific identity can actually connect over SMB.
