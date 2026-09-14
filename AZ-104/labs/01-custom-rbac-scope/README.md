# Lab 01 — Custom RBAC Roles & Scope Hierarchy

**AZ-104 domain:** Manage Azure identities and governance (20–25%) — Manage access to Azure resources
**Cost:** $0 — role definitions and role assignments carry no charge
**Time:** ~20 minutes

## What you'll build

A **custom RBAC role** — "AZ-104 Lab 01 Storage Operator" — that can read, write, and list keys on storage accounts but cannot delete them, narrower than any single built-in role offers. You'll assign that custom role, plus the built-in **Reader** role, to your own signed-in account at resource-group scope. AZ-900 Lab 4 taught RBAC as "pick a built-in role and assign it"; this lab goes one level deeper into where custom roles live and why.

## Deploy

```bash
PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)

az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters principalId=$PRINCIPAL_ID
```

If you'd rather target a test user or group instead of yourself, pass its object ID and set `principalType` accordingly:

```bash
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters principalId=<object-id> principalType=Group
```

## Verify

```bash
az role definition list --custom-role-only true --query "[?roleName=='AZ-104 Lab 01 Storage Operator']" -o json

az role assignment list --resource-group rg-az104-lab01 -o table
```

In the portal: **rg-az104-lab01 → Access control (IAM) → Role assignments** to see both the custom role and Reader listed against your principal.

## Manual tasks (can't be done by Bicep)

1. **(Optional) Create a second test principal.** If you want a principal to assign Reader to that isn't your own account, create a throwaway Entra ID user — `az ad user create --display-name "AZ104 Lab01 Test" --password <temp-password> --user-principal-name az104lab01test@<yourtenant>.onmicrosoft.com` or via the portal (**Microsoft Entra ID → Users → New user**). This requires Entra ID admin rights (Global Administrator or User Administrator) and is entirely skippable — your own signed-in account works fine for everything else in this lab.
2. **Check access for a principal.** In the portal, go to **rg-az104-lab01 → Access control (IAM) → Check access**, search for your principal (or the test user from step 1), and read the effective role assignments it returns at this scope.
3. **Observe the management group hierarchy — read-only.** Open **Management groups** in the portal to see the level above subscriptions. Do not move your subscription into a management group to "test" inheritance unless you're working in a disposable sandbox tenant — moving a production subscription changes policy and RBAC inheritance for everything underneath it.

## Clean up

```bash
az role assignment delete --resource-group $(az group show --name rg-az104-lab01 --query id -o tsv) \
  --assignee $PRINCIPAL_ID --role "AZ-104 Lab 01 Storage Operator"

az role assignment delete --resource-group $(az group show --name rg-az104-lab01 --query id -o tsv) \
  --assignee $PRINCIPAL_ID --role "Reader"

az group delete --name rg-az104-lab01 --yes --no-wait

az role definition delete --name "AZ-104 Lab 01 Storage Operator"
```

Role assignments are deleted before the resource group so the cleanup is explicit and visible; deleting the resource group would also remove the assignments scoped to it, but the custom role definition lives at subscription scope and has to be removed separately regardless.

## Lecture talking points

- **Custom roles exist for least privilege, not convenience.** The built-in "Storage Account Contributor" role grants delete; this lab's custom role deliberately strips that out. The exam tests *when* you'd reach for a custom role: when no built-in role matches the access you actually want to grant, usually because every built-in option is either too broad or missing one specific permission.
- **Scope hierarchy and inheritance — the core exam diagram.** Management group → subscription → resource group → resource. A role assigned at a higher scope flows down to everything beneath it; a role assigned at a lower scope has no effect above it. This lab only assigns at resource-group scope, but `assignableScopes` on the custom role definition is set to the subscription — worth pointing out the definition's scope and the assignment's scope are two different things.
- **Why `assignableScopes` is the subscription, not the resource group.** Custom roles are almost always defined at subscription (or management-group) scope specifically so one definition can be reused across many resource groups later — even though this lab's demo assignment only touches one RG. Defining a custom role scoped to a single resource group is technically legal but defeats the point of writing one.
- **RBAC is additive — there's no subtractive "deny" in a normal assignment.** Azure evaluates every role assigned to a principal across every scope that applies and unions the permissions; you cannot assign a role and then assign a second role to take a permission back. A rare exception — explicit deny assignments — exists in Azure but is provisioned by Microsoft for specific managed scenarios (Azure Blueprints, managed apps); students should know it exists by name but won't be creating one themselves.
- **Direct callback to AZ-900 Lab 4.** That lab taught "assign a built-in role at a scope." This lab keeps the assignment step but swaps in a role you wrote yourself — same mechanism, more control over exactly what's granted.

## What you learned

By completing this lab, you can now:

- Write and deploy a **custom RBAC role definition** with a narrower permission set than any built-in role offers.
- Explain the difference between where a role **definition** is assignable (`assignableScopes`) and where it's actually **assigned** (the role assignment's scope).
- Navigate the Azure scope hierarchy — management group, subscription, resource group, resource — and state how permissions inherit downward through it.
- Use **Access control (IAM) → Check access** to look up a principal's effective permissions at a given scope.
- Explain why RBAC is additive-only in normal use, and name explicit deny assignments as the rare, Microsoft-provisioned exception.
