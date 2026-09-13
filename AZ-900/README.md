# AZ-900: Azure Fundamentals — Course Companion Repo

Companion hands-on labs, Bicep templates, and walkthroughs for the AZ-900 (Microsoft Azure Fundamentals) video course.

This repo is the free, clonable companion to the paid course — students deploy real (near-zero-cost) Azure resources alongside each module instead of only watching slides.

## Repo structure

```
book/           The sellable AZ-900 study guide, structured chapter-for-chapter against
                Microsoft's official skills outline. See book/README.md.
labs/           Nine hands-on labs, one per major exam domain/sub-objective. Each has
                main.bicep + README.md with deploy/verify/cleanup commands and instructor
                talking points.
walkthroughs/   Guided walkthroughs tied to specific labs/modules (portal tours, alert-rule
                deep dives, practice-exam review, etc.) that don't need their own IaC.
docs/           Skills-alignment map (domain -> chapter -> lab) and supporting reference material.
```

## Labs

| # | Lab | Exam Domain | Cost |
|---|-----|-------------|------|
| 1 | [Resource Groups & Tagging](labs/01-resource-groups-tagging/) | Cloud Concepts / Governance | $0 |
| 2 | [Storage Redundancy (LRS/ZRS/GRS)](labs/02-storage-redundancy/) | Core Services — Storage | ~$0 |
| 3 | [Virtual Network & NSGs](labs/03-vnet-nsg/) | Core Services — Networking | $0 |
| 4 | [RBAC Role Assignment](labs/04-rbac-role-assignment/) | Identity, Governance, Compliance | $0 |
| 5 | [Budgets & Cost Alerts](labs/05-budgets-cost-alerts/) | Pricing, SLA & Lifecycle | $0 |
| 6 | [App Service (PaaS)](labs/06-app-service-paas/) | Cloud Concepts — IaaS/PaaS/SaaS | ~$0 |
| 7 | [Resource Locks & Monitor Alerts](labs/07-resource-locks-monitor-alerts/) | Azure Management & Governance | ~$0 |
| 8 | [Azure Policy](labs/08-azure-policy/) | Azure Management & Governance | $0 |
| 9 | [Virtual Machine Basics](labs/09-virtual-machine/) | Azure Architecture & Services — Compute | ~$0.01–0.05 |

Every lab is free or near-free, **except Lab 9**, which deploys a real billable VM (still trivially cheap for a short demo, but the only lab in this repo that isn't $0). Every README ends with a cleanup step — run it right after each demo so nothing lingers on a bill. Lab 7 has an extra cleanup step (removing its resource lock) before the resource group will delete, and Lab 8's cleanup must delete the policy assignment before the policy definition — see those labs' READMEs.

Every lab except Lab 9 has a companion portal walkthrough under [`walkthroughs/`](walkthroughs/) — see that folder's README for the full list. Each assumes the lab is already deployed and tours what it built directly in the Azure Portal, ending with a "What you learned" summary.

## Prerequisites

- An Azure subscription (a free trial or pay-as-you-go account both work — every lab here stays at $0 or near-$0)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and signed in (`az login`)
- Bicep support comes bundled with a recent Azure CLI (`az bicep install` if prompted)

## API versions

Resource API versions in these templates were verified against Microsoft Learn as of **September 2026**. Azure ARM/Bicep API versions do drift over time — if you're watching this months after release and a deployment fails on an API version, check the [Azure Resource Manager template reference](https://learn.microsoft.com/azure/templates/) for the current version of that resource type.

## Book

A complete AZ-900 study guide, structured to match Microsoft's official skills-measured outline exactly — see [`book/README.md`](book/README.md) for status, structure, and build instructions. Builds to PDF/EPUB via Pandoc.

## Course

Full course (video lectures, slide decks, practice exams) is on Udemy — see the skills alignment map in [`docs/course-outline.md`](docs/course-outline.md) for how domains, book chapters, video modules, and labs all map to each other.
