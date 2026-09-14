# Walkthrough — Storage Security: SAS, Network Rules & Customer-Managed Keys (Lab 04)

A guided, portal-first walkthrough of what [Lab 04](../../labs/04-storage-security-access/) deploys. The lab README covers the Bicep deploy/verify/cleanup commands and the CLI-driven manual tasks — this walkthrough is for seeing the same things through the portal UI and comparing the two.

**Prerequisite:** Lab 04 is already deployed (`az deployment group create ...` from the lab README), including the manual container/SAS/policy steps, and you have the resource group open in the [Azure Portal](https://portal.azure.com).

## Part 1 — Read the network rule

1. Open `rg-az104-lab04` and click into the storage account.
2. In the left menu, under **Security + networking**, select **Networking**.
3. On the **Firewalls and virtual networks** tab, confirm **Public network access** is scoped to **Enabled from selected virtual networks and IP addresses**, with your IP listed under **Firewall**.
4. Scroll to **Exceptions** and note **Allow Azure services on the trusted services list to access this storage account** is checked — this is the `bypass: 'AzureServices'` setting from the template.

Notice what this blade does *not* show: nothing here references SAS tokens, roles, or identities. This is purely the "can the request reach the account" layer.

## Part 2 — Read the encryption configuration

1. Still on the storage account, under **Security + networking**, select **Encryption**.
2. Confirm the type is set to **Customer-managed keys**, with your Key Vault and key name/version selected.
3. Click through to the **Key Vault** link on this page — it opens the vault directly.
4. In the vault, go to **Access control (IAM) → Role assignments**, and find the storage account's identity (it shows up by the storage account's own name, not a human's) holding **Key Vault Crypto Service Encryption User**.

This is the chain from the lab's Bicep made visible: identity → role → key access → encryption.

## Part 3 — Generate a SAS token from the portal

1. Navigate into the `demo` container you created in the lab's manual tasks (**Data storage → Containers → demo**).
2. In the container's left menu, select **Shared access tokens** (or, at the account level, **Security + networking → Shared access signature** for an account-level token).
3. Set permissions to **Read**, an expiry a short time from now, and click **Generate SAS token and URL**.
4. Compare the generated **Blob SAS token** string to the one your `az storage container generate-sas` command produced earlier — same structure (`sv=`, `sig=`, `se=`, `sp=`), different signing path depending on whether you used `--as-user`.

## Part 4 — Find the stored access policy

1. Still in the `demo` container, select **Access policy** in the left menu.
2. Under **Stored access policies**, find `demo-read-policy` with the permissions and expiry you set via CLI.
3. Click into it and try changing its expiry or permissions, then cancel without saving — notice this is the single point of control that would immediately affect every SAS token issued against this policy, without you having to track down and individually revoke each token.

## Part 5 — Confirm the key rotation

1. Back at the storage account level, under **Security + networking**, select **Access keys**.
2. Click **Show keys** and note the **Last rotated** timestamp on key1 (primary) and key2 (secondary) — both should show a recent rotation if you ran the CLI commands from the lab's manual tasks.
3. This blade is also where you'd rotate keys manually if you ever need to — the **Rotate key** button next to each one does exactly what `az storage account keys renew` did from the CLI.

## What you learned

Walking through this lab in the portal, you should now be able to:

- **Locate and read a storage account's network firewall rules** in the portal, and distinguish the "reach the account" layer from identity-based access checks.
- **Trace a customer-managed key configuration** from the storage account's Encryption blade through to the Key Vault's role assignments, confirming which identity has access and via which role.
- **Generate a SAS token through the portal UI** and compare its structure to one generated via CLI, recognizing the difference between a key-signed and a user-delegation-signed token.
- **Find and edit a stored access policy** on a container, and explain why editing the policy is a single point of control over every SAS token issued against it.
- **Locate and manually trigger key rotation** from the Access keys blade, and read the last-rotated timestamp for each key.
