# AZ-900: Azure Fundamentals — Course Companion Repo

Companion hands-on labs, Bicep templates, and walkthroughs for the AZ-900 (Microsoft Azure Fundamentals) video course.

This repo is the free, clonable companion to the paid course — students deploy real (near-zero-cost) Azure resources alongside each module instead of only watching slides.

## Repo structure

```
labs/           Six hands-on labs, one per major exam domain. Each has main.bicep + README.md
                with deploy/verify/cleanup commands and instructor talking points.
walkthroughs/   Guided walkthroughs tied to specific modules (portal tours, practice-exam
                review, etc.) that don't need their own IaC.
docs/           Course outline and supporting reference material.
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

Every lab uses only Free-tier or inherently-free resources, and every README ends with a `az group delete` cleanup step — run it right after each demo so nothing lingers on a bill.

## Prerequisites

- An Azure subscription (a free trial or pay-as-you-go account both work — every lab here stays at $0 or near-$0)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and signed in (`az login`)
- Bicep support comes bundled with a recent Azure CLI (`az bicep install` if prompted)

## API versions

Resource API versions in these templates were verified against Microsoft Learn as of **September 2026**. Azure ARM/Bicep API versions do drift over time — if you're watching this months after release and a deployment fails on an API version, check the [Azure Resource Manager template reference](https://learn.microsoft.com/azure/templates/) for the current version of that resource type.

## Course

Full course (video lectures, slide decks, practice exams) is on Udemy — see the course outline in [`docs/course-outline.md`](docs/course-outline.md) for the module breakdown.
