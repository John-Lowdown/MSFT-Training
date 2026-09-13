# Walkthroughs

This folder holds guided walkthroughs that support a course module but don't need their own Bicep/IaC — portal tours, pricing-calculator demos, practice-exam review sessions, and similar.

## Built

- [`07-resource-locks-monitor-alerts/`](07-resource-locks-monitor-alerts/) — portal-first walkthrough of [Lab 7](../labs/07-resource-locks-monitor-alerts/): finding and testing the resource lock, reading the Monitor alert rule's configuration, cleanup. Ends with a "What you learned" summary.
- [`08-azure-policy/`](08-azure-policy/) — portal-first walkthrough of [Lab 8](../labs/08-azure-policy/): reading the policy definition's JSON, watching the Compliance tab lag behind an instant deny, and comparing `Deny` vs. `Audit` effects side by side. Ends with a "What you learned" summary.

No dedicated walkthrough for Lab 9 (Virtual Machine) — beyond SSH'ing in, there isn't much the portal shows that the lab's own CLI verify steps don't already cover. Add one if that changes (e.g., if the lab grows to demonstrate Azure Bastion or VM extensions).

## Planned

Mapped to the skills alignment in [`../docs/course-outline.md`](../docs/course-outline.md):

- **Module 1:** Exam registration walkthrough (Pearson VUE / online proctoring checklist, screen-recorded)
- **Module 3:** Azure Marketplace tour — deploying a resource from the Marketplace vs. from a template
- **Module 4:** Portal-vs-CLI-vs-Bicep side-by-side — deploying the same resource three ways
- **Module 6:** Live walkthrough of the Pricing Calculator using a realistic scenario (note: the TCO Calculator was retired by Microsoft in August 2025 — don't build a walkthrough comparing it to the Pricing Calculator)
- **Module 7:** Practice exam review — screen-recorded read-through of missed-question patterns

Add one subfolder per walkthrough as they're built (e.g. `01-exam-registration/`) following the same `README.md`-first convention as `labs/`.
