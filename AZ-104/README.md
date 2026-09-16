# AZ-104: Azure Administrator — Course Companion Repo

Companion hands-on labs, Bicep templates, and walkthroughs for the AZ-104 (Microsoft Certified: Azure Administrator Associate) study guide and video course — the second course in the AZ-900 → AZ-104 → AZ-305 progression.

This repo is the free, clonable companion to the paid course — students deploy real Azure resources alongside each module instead of only watching slides, extending the [AZ-900 labs](../AZ-900/) to admin-level configuration depth (custom RBAC roles, Policy initiatives, VNet peering, load balancing, Log Analytics, Azure Backup) rather than just fundamentals-level provisioning.

## Repo structure

```
labs/           Fourteen hands-on labs, one per major exam sub-topic. Each has main.bicep +
                README.md with deploy/verify/cleanup commands and instructor talking points.
                Labs call out a "Manual tasks" section for anything that genuinely can't be
                expressed as a Bicep resource (SAS tokens, VM resize, slot swaps, restores).
walkthroughs/   Guided, click-by-click portal walkthroughs tied to each lab — tour what the
                Bicep deployed, or (for manual-only topics like Site Recovery) the primary
                walkthrough of doing the thing by hand.
docs/           Skills-alignment map (domain -> module -> lab) and supporting reference material.
```

## Labs

| # | Lab | Exam Domain | Cost |
|---|-----|-------------|------|
| 1 | [Custom RBAC Roles & Scope Hierarchy](labs/01-custom-rbac-scope/) | Identities & Governance | $0 |
| 2 | [Azure Policy: Initiatives & Remediation](labs/02-azure-policy-initiatives/) | Identities & Governance | $0 |
| 3 | [Resource Locks, Cost Budgets & Resource Moves](labs/03-governance-tags-cost/) | Identities & Governance | ~$0 |
| 4 | [Storage Security: SAS, Network Rules & CMK](labs/04-storage-security-access/) | Storage | ~$0 |
| 5 | [Storage Lifecycle, Versioning & Object Replication](labs/05-storage-lifecycle-protection/) | Storage | $0 |
| 6 | [VM Deployment, Availability Zones & Managed Disks](labs/06-vm-availability-disks/) | Compute | **~$0.01–0.05/hr** |
| 7 | [VM Scale Sets & Custom Autoscale](labs/07-vmss-autoscale/) | Compute | **~$0.01–0.05/hr × instances** |
| 8 | [Containers: Registry, Instances & Container Apps](labs/08-containers-acr-aci-apps/) | Compute | ~$0 (near-$0 if deleted promptly) |
| 9 | [App Service: Deployment Slots & VNet Integration](labs/09-app-service-advanced/) | Compute | **~$0.10/hr (Standard S1)** |
| 10 | [VNet Peering & User-Defined Routes](labs/10-vnet-peering-routing/) | Virtual Networking | ~$0 |
| 11 | [NSGs, ASGs, Bastion & Private Endpoints](labs/11-nsg-asg-bastion-endpoints/) | Virtual Networking | **~$0.19/hr (Bastion) — most expensive lab in this repo** |
| 12 | [Standard Load Balancer & Azure DNS](labs/12-load-balancer-dns/) | Virtual Networking | ~$0 |
| 13 | [Log Analytics, Diagnostic Settings & KQL](labs/13-monitor-log-analytics/) | Monitor & Maintain | ~$0 |
| 14 | [Recovery Services Vault, Backup & Restore](labs/14-backup-recovery/) | Monitor & Maintain | ~$0 (more if you opt into the optional Site Recovery section) |

Every lab's README states its cost plainly and bolds any real hourly charge — **unlike AZ-900, several of these labs are genuinely billable by the hour** (VMs, a Standard-tier App Service plan, Azure Bastion). Delete each one right after its demo; don't leave Labs 6, 7, 9, or 11 running overnight. Every README ends with a cleanup step in the right order — Lab 2 (policy initiative before definitions), Lab 3 (remove the lock before it blocks a move or delete), and Lab 14 (disable backup protection before the vault can be deleted) each have a real, exam-relevant "this resource actively resists deletion" gotcha baked into cleanup — see those labs' READMEs.

Every lab has a companion portal walkthrough under [`walkthroughs/`](walkthroughs/) — see that folder's README for the full list. Each assumes the lab is already deployed and tours what it built directly in the Azure Portal (or, for manual-only topics, walks the steps by hand), ending with a "What you learned" summary.

## Prerequisites

- An Azure subscription (a free trial or pay-as-you-go account both work, but read each lab's cost line first — this course is not uniformly $0 the way AZ-900 was)
- Completion of, or familiarity with, the [AZ-900 course/repo](../AZ-900/) in this project
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and signed in (`az login`)
- Bicep support comes bundled with a recent Azure CLI (`az bicep install` if prompted)
- Sufficient Entra ID / subscription permissions to create custom RBAC role definitions and policy assignments (Lab 1–2) — typically Owner or User Access Administrator at the scope you're working in

## API versions

Resource API versions in these templates were selected as real, GA (non-preview) versions believed current as of **September 2026**, following the same convention as the AZ-900 repo. Azure ARM/Bicep API versions do drift over time — if you're working through this months after release and a deployment fails on an API version, check the [Azure Resource Manager template reference](https://learn.microsoft.com/azure/templates/) for the current version of that resource type.

## Course

Full course (video lectures, slide decks, practice exams) mirrors the AZ-900 course's Udemy delivery model — see the skills alignment map in [`docs/course-outline.md`](docs/course-outline.md) for how domains, video modules, and labs all map to each other, including which exam sub-bullets have no dedicated Microsoft Learn module and how this repo's labs close that gap.

## Status

- [x] Course outline drafted and aligned against the official AZ-104 study guide (skills measured as of April 17, 2026) and all 32 modules across the six official Learn paths
- [x] All 14 hands-on labs built — Bicep + README + portal walkthrough each
- [ ] Study Guide PDF — not part of this repo (lives alongside the course outline source materials)
- [ ] Video/lecture scripts — not yet started
- [ ] Practice-exam question bank — not yet started
