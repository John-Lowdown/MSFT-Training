# Walkthrough — Microsoft Entra Users, Groups & Licensing (Lab 15)

The click-by-click version of [Lab 15](../../labs/15-entra-users-groups-licensing/). Because Lab 15 is itself a manual/portal-first lab — there's no `main.bicep` to deploy and then tour afterward — this walkthrough and the lab README necessarily overlap more than the walkthroughs for the Bicep-first labs (1–14) do. That's expected for this lab's delivery type: this document adds value by spelling out the exact blade names, button labels, and screen order behind each task, rather than the command-and-concept level the lab README works at.

**Prerequisite:** you have **User Administrator** (or Global Administrator) rights in an Entra ID tenant, the Azure Portal open at [portal.azure.com](https://portal.azure.com), and Azure CLI signed in (`az login`) if you're following the CLI steps alongside the portal ones.

## Part 1 — Create a user by hand

1. In the portal search bar, go to **Microsoft Entra ID**.
2. Left-hand menu → **Users** → **+ New user** → **Create new user**.
3. On the **Basics** tab: **User principal name** = `az104lab15.portal@<yourtenant>.onmicrosoft.com`, **Display name** = `AZ104 Lab15 Portal User`, and either type a password or leave **Auto-generate password** checked.
4. Switch to the **Properties** tab. Scroll to **Job information** and set **Department** to `Sales`. Scroll further to **Settings** and set **Usage location** to any country.

   ![Microsoft Entra ID — creating a new user, showing the display name, UPN, and usage location fields](../01-custom-rbac-scope/images/az104-item04-step3-properties-REQUIRED.png)

   **Step shown:** Create new user → Properties tab → Usage location field. *(Reused from Lab 1's walkthrough — same blade, same required field.)*

5. **Review + create**, then **Create**. The new user appears in the **Users** list within a few seconds.

## Part 2 — Bulk-create the rest

**If you're using the script** (`create-users.sh` from the lab folder): run it from a terminal with `TENANT_DOMAIN` set, then refresh **Microsoft Entra ID → Users** in the portal — the three new users appear once the CLI calls complete, no portal interaction needed for creation itself. Open each one and set **Department = Sales** and a **Usage location** on the **Properties** tab, same fields as Part 1 step 4.

**If you're using the portal's own bulk path instead:** **Users → Bulk operations → Bulk create**, download the CSV template, fill one row per user (the template's own columns cover UPN, display name, and password — usage location and department aren't in the default template and still need to be set per-user afterward, same as the script path), then **Submit**. A background job processes the upload; check its status under **Bulk operation results** in the same blade.

## Part 3 — Build the dynamic group and compare it to an assigned one

1. **Microsoft Entra ID → Groups → New group.**
2. **Group type** = Security, **Group name** = `AZ104-Lab15-Sales-Dynamic`.
3. **Membership type** dropdown → switch from **Assigned** to **Dynamic User**. Notice the **Members** section disappears and an **Add dynamic query** link appears in its place — that's the visible tell that membership is no longer something you edit by hand.
4. Click **Add dynamic query**. In the rule builder: **Property** = Department, **Operator** = Equals, **Value** = Sales. Or click **Edit** to switch to the raw syntax box and paste:

   ```
   (user.department -eq "Sales")
   ```

5. **Save**, then **Create** on the main group blade.
6. Open the group and click **Members**. It may read empty for a minute or two — dynamic membership evaluation runs on a delay, not instantly on group creation. Refresh after a few minutes and your Task 1/2 users (all `department = Sales`) should appear, added automatically, with no **+ Add members** button anywhere on this tab.

Now create the contrast group from the CLI (there's no portal advantage here — the commands are the fast path):

```bash
az ad group create --display-name "AZ104-Lab15-Sales-Assigned" --mail-nickname az104lab15salesassigned
az ad group member add --group "AZ104-Lab15-Sales-Assigned" --member-id <user-object-id>
```

Open **`AZ104-Lab15-Sales-Assigned` → Members** in the portal — this one has a visible **+ Add members** button, because membership here is exactly the static list you put into it.

## Part 4 — Group-based licensing (skip the assignment if your tenant has no spare SKU)

1. Open **`AZ104-Lab15-Sales-Assigned` → Licenses**.
2. If the **+ Assignments** button leads to a list of available product SKUs, pick one, leave the default service plans selected, and **Save**. If the list is empty (a Microsoft Entra ID Free trial tenant, most commonly), stop here — you've still seen the blade the exam bullet is asking about.
3. Back on the group's **Licenses** page, the assignment (if you made one) shows a **Provisioning status** column per group member — this is worth pointing out live: license provisioning to each member happens asynchronously, the same delayed pattern as dynamic membership evaluation.

## Part 5 — Invite a guest and compare the object

1. **Microsoft Entra ID → Users → + New user → Invite external user.**
2. **Email address** = an address you control, then **Review + invite** → **Invite**.
3. Back on **Users**, find the new row. Its **User type** column reads **Guest**, and until the invite is redeemed, hovering or opening the user shows an **Invitation accepted** field set to **Pending acceptance**.
4. Open the guest's own **Profile** blade side by side (in a second tab) with your Task 1 portal user's **Profile** blade. The guest has no **Reset password** action available the way a member user does — password reset for a guest happens at their home identity provider, not in your tenant.

## Part 6 — Read the SSPR policy

1. **Microsoft Entra ID → Password reset.**
2. **Properties** page (opens by default): read the **Self service password reset enabled** radio — **None**, **Selected**, or **All**. Do not change it unless you're in a disposable test tenant.
3. Left-hand menu → **Authentication methods**: read **Number of methods required to reset** (typically 1 or 2) and which methods below it are toggled **Yes**.
4. Left-hand menu → **Registration**: read whether users are being prompted to register authentication methods, and on what schedule (**Require users to register when signing in** = Yes/No).

This entire part is look-only in a shared or production tenant — the setting applies tenant-wide the instant you save a change, with no per-user preview.

## Clean up

Follow the lab README's **Clean up** section (`az ad user delete` / `az ad group delete` for every object created above). Remember deleted users land in a 30-day soft-deleted state — `az ad user list` won't show them, but a permanent purge needs the Graph API's `/directory/deletedItems` endpoint, out of scope for this walkthrough.

## What you learned

Walking through this lab in the portal, you should now be able to:

- Create a user via the portal's **New user** blade and set the usage location and department fields the rest of the lab depends on.
- Tell a **dynamic membership** group apart from an **assigned** one purely by the UI — the missing **+ Add members** button and the **Add dynamic query** rule builder.
- Locate **group-based licensing** on a group's **Licenses** blade and read per-member provisioning status.
- Identify a **B2B guest user** in the **Users** list by its **User type** and **Invitation accepted** state, and explain why it has no in-tenant password reset action.
- Navigate to **Microsoft Entra ID → Password reset** and read the current SSPR enablement scope and registration requirements without changing them.
