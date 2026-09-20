# Lab 15 — Microsoft Entra Users, Groups & Licensing

**AZ-104 domain:** Manage Azure identities and governance (20–25%) — Manage Microsoft Entra users and groups
**Delivery type:** Manual + CLI script — **this lab has no `main.bicep`.** Entra ID users, groups, and license assignments are Microsoft Graph objects, not ARM resources, so there's nothing here for `az deployment` to deploy. Everything in this lab is either a portal click-through or an `az ad` / Graph-backed CLI command, plus one small bulk-creation script (`create-users.sh`) to demonstrate "bulk" honestly instead of asking you to click **+ New user** ten times.
**Cost:** $0 for everything you'll actually do in this lab — creating users, groups, dynamic membership rules, a guest invitation, and reading SSPR policy carry no charge. **Group-based license assignment** would consume a real license seat if you have paid Microsoft 365/Entra ID P1/P2 SKUs in your tenant; that step is explicitly optional/observe-only if you don't (see Task 4).
**Time:** ~25 minutes

## What you'll build

A handful of demo users — one created by hand in the portal, three more created in bulk via `create-users.sh` — a security group with **dynamic membership** driven by a rule (`user.department -eq "Sales"`), contrasted against a plain **assigned**-membership group, a look at **group-based licensing** (optional if your tenant has no spare license), a **B2B guest user** invited by email, and a guided look at where your tenant's **self-service password reset (SSPR)** policy actually lives.

This closes a real gap in this repo: Lab 1 covers RBAC (sub-objective "Manage access to Azure resources") and assumes a user principal already exists to assign roles to. This lab is where that principal actually gets created, and where the rest of "Manage Microsoft Entra users and groups" — group types, licensing, external users, SSPR — gets exercised hands-on for the first time in this course. AZ-900 only covered Entra ID conceptually; nothing in that course had you create a user or a group.

## Prerequisites

- **User Administrator** (or Global Administrator) in your Entra ID tenant — needed to create users, groups, and invite guests.
- Azure CLI signed in (`az login`) with `az ad` commands available (bundled with the CLI, no extra extension needed).
- Your tenant's initial domain, e.g. `contoso.onmicrosoft.com` — run `az account show --query tenantDefaultDomain -o tsv` if you don't already know it, or find it under **Microsoft Entra ID → Overview → Primary domain**.
- (Optional, Task 4 only) a spare Microsoft 365 or Entra ID P1/P2 license in the tenant. A free trial tenant with only "Microsoft Entra ID Free" has nothing to assign — that's fine, skip Task 4's actual assignment and just read the blade.

## Task 1 — Create one user via the portal

1. **Microsoft Entra ID → Users → + New user → Create new user.**
2. Fill in **User principal name** (`az104lab15.portal@<yourtenant>.onmicrosoft.com`), **Display name**, and a password (or let Entra auto-generate one).
3. Under **Properties**, set **Usage location** — pick any country. This is a hard prerequisite: Entra ID refuses to let you assign a license to a user with no usage location set, so this step has to happen at creation time or before licensing, not after.
4. Set **Job info → Department** to `Sales` — this is what Task 2's dynamic group rule will match on.
5. Click **Review + create**, then **Create**.

```bash
az ad user show --id az104lab15.portal@<yourtenant>.onmicrosoft.com --query "{upn:userPrincipalName, displayName:displayName}" -o table
```

## Task 2 — Create several more users in bulk

Two ways to do this exist; use whichever fits how you're following along:

**CLI script** — `create-users.sh` in this lab's folder loops over `az ad user create` to create three more demo users (`az104lab15-sales1/2/3`):

```bash
chmod +x create-users.sh
TENANT_DOMAIN=<yourtenant>.onmicrosoft.com ./create-users.sh
```

**Portal-native alternative** — Entra ID's own bulk-create path is **Microsoft Entra ID → Users → Bulk operations → Bulk create**, which downloads a CSV template, expects one row per user, and uploads it back for provisioning. Both exist and both count as "bulk creation" for exam purposes; the script is here because a screen-recorded lab can't click through a spreadsheet upload as cleanly as it can show three users appearing from one command.

After either path, set each new user's **Usage location** and **Department = Sales** the same way you did in Task 1 (the script doesn't set these — Graph's user-create call takes them as separate properties you'd normally pass with `--fields` or a follow-up `az rest` call, left out here to keep the script short; do it manually in the portal for the three bulk users, or skip it and just get the RBAC-adjacent point: bulk creation works).

```bash
az ad user list --filter "startswith(displayName,'AZ104 Lab15')" --query "[].{upn:userPrincipalName, dept:department}" -o table
```

## Task 3 — Dynamic membership group vs. assigned membership group

Entra ID groups come in two membership types, and the exam tests the distinction directly:

- **Assigned** — a static, manually-maintained list. You add and remove members yourself; nothing changes automatically.
- **Dynamic** — Entra ID evaluates a **membership rule** against every user's attributes and adds/removes them automatically as those attributes change.

**Create the dynamic group:**

1. **Microsoft Entra ID → Groups → New group.**
2. **Group type:** Security. **Group name:** `AZ104-Lab15-Sales-Dynamic`.
3. **Membership type:** Dynamic User.
4. Click **Add dynamic query**, then either use the rule builder (**Property:** Department, **Operator:** Equals, **Value:** Sales) or paste the rule directly:

   ```
   (user.department -eq "Sales")
   ```

5. Save the rule, then **Create**. Entra ID evaluates membership asynchronously — it can take a few minutes for your Task 1/2 users to actually appear as members, since they all have `department = Sales`.

**Create the assigned group for contrast:**

```bash
az ad group create --display-name "AZ104-Lab15-Sales-Assigned" --mail-nickname az104lab15salesassigned

az ad group member add \
  --group "AZ104-Lab15-Sales-Assigned" \
  --member-id $(az ad user show --id az104lab15.portal@<yourtenant>.onmicrosoft.com --query id -o tsv)
```

Compare the two in the portal: the dynamic group's **Members** tab has no **+ Add members** button (membership is rule-derived, not editable by hand); the assigned group's does.

## Task 4 — Group-based licensing (optional — needs a real license SKU)

The modern recommended pattern is to license the **group**, not each user individually — one change point instead of N. If your tenant has a spare license:

1. **Microsoft Entra ID → Groups → `AZ104-Lab15-Sales-Assigned` → Licenses → + Assignments.**
2. Pick an available product/SKU, then **Save**.
3. Every current (and future) member of that group inherits the license automatically; removing a user from the group removes the license the same way.

If your tenant shows no assignable SKUs (a bare "Microsoft Entra ID Free" trial, for example), skip the assignment itself — just open the **Licenses** blade so you've seen where the setting lives. The exam bullet is "manage licenses in Microsoft Entra ID," and knowing the blade and the group-based pattern satisfies that even without a SKU to spend.

## Task 5 — Invite a B2B guest user

1. **Microsoft Entra ID → Users → + New user → Invite external user.**
2. Enter an email address you control (a second personal address works fine — the invite just sends a redemption link, nothing is charged).
3. Add a personal message if you want, then **Review + invite**.
4. The invited account shows up immediately in **Users**, in a **Pending acceptance** state, before the invite is even opened.

```bash
az ad user list --filter "userType eq 'Guest'" --query "[].{upn:userPrincipalName, type:userType, state:externalUserState}" -o table
```

What's different about this object versus the users from Tasks 1–2: **UserType** is `Guest`, not `Member`; your tenant never sees or manages a password for it — the guest signs in through their own home identity provider (another Entra tenant, a Microsoft account, or Google, depending on what they used to redeem the invite); and it still lives in the same directory and can be added to groups and assigned roles like any other principal.

## Task 6 — Locate and read the SSPR policy (read-only)

**Self-service password reset is a tenant-wide policy, not a per-user setting** — there's no "enable SSPR for this one user" toggle. Changing it affects every user in the tenant at once, so unless you're working in a disposable test tenant, treat this task as read/observe only, the same caution Lab 1 used for management groups.

1. **Microsoft Entra ID → Password reset.**
2. On the **Properties** page, read the current setting: **None**, **Selected** (a specific group), or **All**.
3. Open **Authentication methods** and read the registration requirements: how many methods a user must register (commonly "1" or "2"), and which methods are enabled (Mobile app, email, phone, security questions, etc.).
4. Open **Registration** to see the enforcement state — whether users are being actively prompted to register the required methods.

Don't change any of these settings against a production or shared tenant. If you have a disposable test tenant, feel free to flip **Self service password reset enabled** to **Selected** and add your Task 3 assigned group, just to see the group-scoping option exist — then set it back.

## Clean up

Delete the demo users, the dynamic group, the assigned group, and revoke the guest invitation:

```bash
# Users created in Tasks 1 and 2
az ad user delete --id az104lab15.portal@<yourtenant>.onmicrosoft.com
az ad user delete --id az104lab15-sales1@<yourtenant>.onmicrosoft.com
az ad user delete --id az104lab15-sales2@<yourtenant>.onmicrosoft.com
az ad user delete --id az104lab15-sales3@<yourtenant>.onmicrosoft.com

# Groups from Task 3
az ad group delete --group "AZ104-Lab15-Sales-Dynamic"
az ad group delete --group "AZ104-Lab15-Sales-Assigned"

# Guest invitation from Task 5 — deleting the user object revokes access
az ad user delete --id "<guest-object-id-from-az-ad-user-list>"
```

A deleted Entra user doesn't disappear immediately — it goes to a **soft-deleted** state for 30 days, recoverable in that window. `az ad user list --filter "startswith(displayName,'AZ104')"` won't show them once deleted, but they're not gone; a real permanent purge requires the Microsoft Graph `/directory/deletedItems` endpoint, which is out of scope to script here — just know the behavior exists so a "deleted" user reappearing in a tenant-wide search 5 minutes later doesn't look like a bug. This is the same "some things resist deletion" pattern this repo's Lab 3 (locks) and Lab 14 (backup vaults) already demonstrated.

## Lecture talking points

- **Dynamic vs. assigned group membership is a direct, frequently-tested exam distinction.** Assigned = you maintain the list by hand. Dynamic = Entra ID evaluates a rule against user attributes and maintains the list for you. Know that dynamic groups can be dynamic-user *or* dynamic-device, and that rule evaluation isn't instant — it happens on a delay, not the moment an attribute changes.
- **Group-based licensing beats per-user assignment at scale.** License 500 users individually and a SKU change is 500 edits; license the group they're all members of and it's one. This is also why usage location and department (or whatever attribute drives the dynamic rule) need to be right from the moment a user is created — get them wrong and licensing or group membership silently doesn't happen.
- **Usage location is a hard prerequisite for licensing, not a nice-to-have.** Entra ID will not let you assign a license to a user with no usage location set — this trips people up because the field is easy to skip during user creation and the resulting failure isn't obviously about usage location unless you already know to look for it.
- **A B2B guest user is a different UserType with a different sign-in path — but the same directory.** No password managed by your tenant, sign-in happens through the guest's home identity provider, `UserType` is `Guest` instead of `Member` — but it can still be added to groups, assigned roles, and shows up in the same **Users** list as everyone else.
- **SSPR is configured once, tenant-wide — not per user.** Direct callback to Lab 1's scope-hierarchy theme: some settings live above the individual object and changing them changes the experience for everyone under that scope at once. Treat the live policy as something to locate and read, not something to casually toggle in a shared tenant.
- **Bulk creation has two legitimate paths, both testable.** `az ad user create` in a loop (or any script/automation calling Graph) and the portal's CSV-based **Bulk create users** flow are both "create users in bulk" for exam purposes — know that both exist rather than assuming only one counts.

## What you learned

By completing this lab, you can now:

- Create an Entra ID user individually through the portal, and in bulk via both an `az ad user create` script and the portal's CSV bulk-create path.
- Explain the difference between **assigned** and **dynamic** group membership, and write a basic dynamic membership rule (`user.department -eq "Sales"`).
- Assign a license using **group-based licensing** and explain why it's preferred over per-user assignment at scale.
- State why **usage location** must be set before a user can receive a license.
- Invite a **B2B guest user** and identify what's different about a guest object (`UserType`, sign-in path) versus a normal member.
- Locate your tenant's **SSPR policy** (Password reset blade) and read its current enablement state and registration requirements, without needing to change them.
