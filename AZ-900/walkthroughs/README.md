# Walkthroughs

This folder holds guided walkthroughs that support a course module but don't need their own Bicep/IaC — portal tours, pricing-calculator demos, practice-exam review sessions, and similar.

## Built

Every lab except Lab 9 has a matching portal-first walkthrough — assumes the lab is already deployed, tours what it built in the Azure Portal, and ends with a "What you learned" summary.

- [`01-resource-groups-tagging/`](01-resource-groups-tagging/) — [Lab 1](../labs/01-resource-groups-tagging/): reading tags, finding a subscription-scoped deployment, proving live that tags don't cascade to resources deployed inside the group.
- [`02-storage-redundancy/`](02-storage-redundancy/) — [Lab 2](../labs/02-storage-redundancy/): comparing LRS/ZRS/GRS side by side, finding the GRS paired region, and pointing at the exact portal checkbox that answers the GRS-vs-RA-GRS exam trap.
- [`03-vnet-nsg/`](03-vnet-nsg/) — [Lab 3](../labs/03-vnet-nsg/): reading both NSGs' rules, revealing the default rules nobody wrote, and confirming the priority/first-match model against real priority numbers.
- [`04-rbac-role-assignment/`](04-rbac-role-assignment/) — [Lab 4](../labs/04-rbac-role-assignment/): reading a role assignment's three components via Access Control (IAM), using "Check access," and surfacing why RBAC being additive means the lab's own Reader assignment won't feel like anything changed.
- [`05-budgets-cost-alerts/`](05-budgets-cost-alerts/) — [Lab 5](../labs/05-budgets-cost-alerts/): reading the budget's thresholds in Cost Management, comparing real (tiny) spend against it, and an honest note about why this demo won't email you.
- [`06-app-service-paas/`](06-app-service-paas/) — [Lab 6](../labs/06-app-service-paas/): visiting the live app, distinguishing the App Service Plan from the Web App, and finding F1's limits as literally disabled portal controls.
- [`07-resource-locks-monitor-alerts/`](07-resource-locks-monitor-alerts/) — [Lab 7](../labs/07-resource-locks-monitor-alerts/): finding and testing the resource lock, reading the Monitor alert rule's configuration, cleanup.
- [`08-azure-policy/`](08-azure-policy/) — [Lab 8](../labs/08-azure-policy/): reading the policy definition's JSON, watching the Compliance tab lag behind an instant deny, and comparing `Deny` vs. `Audit` effects side by side.

No dedicated walkthrough for Lab 9 (Virtual Machine) — beyond SSH'ing in, there isn't much the portal shows that the lab's own CLI verify steps don't already cover. Add one if that changes (e.g., if the lab grows to demonstrate Azure Bastion or VM extensions).

## Planned

Mapped to the skills alignment in [`../docs/course-outline.md`](../docs/course-outline.md):

- **Module 1:** Exam registration walkthrough (Pearson VUE / online proctoring checklist, screen-recorded)
- **Module 3:** Azure Marketplace tour — deploying a resource from the Marketplace vs. from a template
- **Module 4:** Portal-vs-CLI-vs-Bicep side-by-side — deploying the same resource three ways
- **Module 6:** Live walkthrough of the Pricing Calculator using a realistic scenario (note: the TCO Calculator was retired by Microsoft in August 2025 — don't build a walkthrough comparing it to the Pricing Calculator)
- **Module 7:** Practice exam review — screen-recorded read-through of missed-question patterns

Add one subfolder per walkthrough as they're built (e.g. `01-exam-registration/`) following the same `README.md`-first convention as `labs/`.
