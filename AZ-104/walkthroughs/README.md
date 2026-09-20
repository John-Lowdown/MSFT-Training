# Walkthroughs

This folder holds guided, click-by-click portal walkthroughs that support a lab — touring what its Bicep deployed — or, for the handful of genuinely manual-only exam topics (Entra ID's role in Lab 1, Site Recovery in Lab 14, and the whole of Lab 15's Entra users/groups/licensing), the primary walkthrough of doing the thing by hand in the portal.

## Built

Every lab has a matching portal-first walkthrough — assumes the lab is already deployed, tours what it built in the Azure Portal, and ends with a "What you learned" summary.

- [`01-custom-rbac-scope/`](01-custom-rbac-scope/) — [Lab 1](../labs/01-custom-rbac-scope/): reading both role assignments and a custom role's JSON, using Check access, and a read-only tour of management groups.
- [`02-azure-policy-initiatives/`](02-azure-policy-initiatives/) — [Lab 2](../labs/02-azure-policy-initiatives/): opening the grouped initiative and its managed identity, reading Compliance, and running a remediation task.
- [`03-governance-tags-cost/`](03-governance-tags-cost/) — [Lab 3](../labs/03-governance-tags-cost/): reading the two-threshold budget, watching a locked resource's Move fail, succeeding on an unlocked one, and a tour of Advisor's cost recommendations.
- [`04-storage-security-access/`](04-storage-security-access/) — [Lab 4](../labs/04-storage-security-access/): reading the network ACL and customer-managed-key encryption blades, then generating a SAS token and a stored access policy in the portal.
- [`05-storage-lifecycle-protection/`](05-storage-lifecycle-protection/) — [Lab 5](../labs/05-storage-lifecycle-protection/): reading the lifecycle rule and object-replication status, then watching versioning and soft delete actually catch a manual overwrite/delete.
- [`06-vm-availability-disks/`](06-vm-availability-disks/) — [Lab 6](../labs/06-vm-availability-disks/): reading the managed disk's SKU and the VM's assigned zone, and browsing the filtered resize list.
- [`07-vmss-autoscale/`](07-vmss-autoscale/) — [Lab 7](../labs/07-vmss-autoscale/): reading the scale-out/scale-in rule pair and the instance limit range, and an honest note about why it won't fire in a short demo.
- [`08-containers-acr-aci-apps/`](08-containers-acr-aci-apps/) — [Lab 8](../labs/08-containers-acr-aci-apps/): touring the registry, the running container instance's logs, and the Container App's scale settings side by side.
- [`09-app-service-advanced/`](09-app-service-advanced/) — [Lab 9](../labs/09-app-service-advanced/): the deployment slots blade and a swap, the VNet integration status, and where custom domains/backup live for later.
- [`10-vnet-peering-routing/`](10-vnet-peering-routing/) — [Lab 10](../labs/10-vnet-peering-routing/): reading both sides of a peering, confirming a route table is actually associated to a subnet (not just created), and the public IP's SKU/zone fields.
- [`11-nsg-asg-bastion-endpoints/`](11-nsg-asg-bastion-endpoints/) — [Lab 11](../labs/11-nsg-asg-bastion-endpoints/): an NSG rule targeting an ASG, effective security rules merging defaults with custom rules, connecting through Bastion, and a private endpoint's approved connection + auto-registered DNS record.
- [`12-load-balancer-dns/`](12-load-balancer-dns/) — [Lab 12](../labs/12-load-balancer-dns/): tracing one request through backend pools/health probes/LB rules, the explicit outbound rule Standard SKU requires, and the DNS zone's auto-generated NS records.
- [`13-monitor-log-analytics/`](13-monitor-log-analytics/) — [Lab 13](../labs/13-monitor-log-analytics/): running a real KQL query against the workspace, confirming the diagnostic setting's categories/destination, and (optionally) a flow log's target and destination workspace.
- [`14-backup-recovery/`](14-backup-recovery/) — [Lab 14](../labs/14-backup-recovery/): the vault and backup policy, protected-VM restore points and the Restore VM wizard, and a clearly optional final section on Site Recovery's Replicate/Failover wizards.
- [`15-entra-users-groups-licensing/`](15-entra-users-groups-licensing/) — [Lab 15](../labs/15-entra-users-groups-licensing/): creating a user by hand and in bulk, building a dynamic-membership group next to an assigned one, group-based licensing, inviting a B2B guest, and reading the tenant's SSPR policy.

## Planned

Mapped to the skills alignment in [`../docs/course-outline.md`](../docs/course-outline.md):

- **Module 1:** Administrator tooling primer — Cloud Shell, Bash vs. PowerShell side-by-side, first ARM/Bicep deploy from VS Code
- **Module 4:** Export-template *portal* walkthrough (click-by-click through the Export template blade) — the CLI equivalent (`az group export` + `az bicep decompile`) is already a manual task in [Lab 6](../labs/06-vm-availability-disks/), this would add the portal-native version
- **Module 5:** Application Gateway tour — Layer 7 routing contrasted live against Lab 12's Layer 4 Load Balancer (no dedicated lab yet)
- **Module 7:** Capstone scenario walkthrough — deploying the full cross-domain scenario sketched in the course outline's Module 7 section as one guided session

Add one subfolder per walkthrough as they're built (e.g. `16-application-gateway/`) following the same `README.md`-first convention as `labs/`.
