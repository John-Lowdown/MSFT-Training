# AZ-900 Skills Alignment (3 Domains)

Master alignment map for this repo's AZ-900 video course, matching Microsoft's official skills-measured outline for Exam AZ-900 (per the [official study guide](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-900), skills as of July 20, 2026). This document is the single source of truth for how domains, the video course's modules, and the labs/walkthroughs map to each other.

> **Re-confirm before recording.** Microsoft revises the skills outline and domain weightings periodically — check the live study guide link above immediately before recording new video content.

---

## Domain 1 — Describe cloud concepts (25–30%)

| Sub-objective | Video module (legacy) | Lab/walkthrough |
|---|---|---|
| Describe cloud computing | Module 2 (Cloud Concepts) | — |
| Describe the benefits of using cloud services | Module 2 | — |
| Describe cloud service types (IaaS/PaaS/SaaS) | Module 2 / Module 3 | Lab 6 (App Service) |

## Domain 2 — Describe Azure architecture and services (35–40%)

| Sub-objective | Video module (legacy) | Lab/walkthrough |
|---|---|---|
| Core architectural components of Azure | Module 4 (Management Tools) | Lab 1 (Resource Groups & Tagging) |
| Azure compute and networking services | Module 3 (Core Azure Services) | Lab 3 (VNet & NSG), Lab 6 (App Service), Lab 9 (Virtual Machine) |
| Azure storage services | Module 3 | Lab 2 (Storage Redundancy) |
| Azure identity, access, and security | Module 5 (Security, Privacy, Compliance) | Lab 3 (NSGs), Lab 4 (RBAC) |

## Domain 3 — Describe Azure management and governance (30–35%)

| Sub-objective | Video module (legacy) | Lab/walkthrough |
|---|---|---|
| Cost management in Azure | Module 6 (Pricing & SLAs) | Lab 5 (Budgets & Cost Alerts), Pricing Calculator walkthrough |
| Governance and compliance tools | Module 5 | Lab 1 (Tagging), Lab 4 (RBAC), Lab 7 (Resource Locks), Lab 8 (Azure Policy) |
| Managing and deploying Azure resources | Module 4 | All 9 labs (CLI/Bicep); Portal-vs-CLI-vs-Bicep walkthrough |
| Monitoring tools in Azure | Module 6 | Lab 7 (Resource Locks & Monitor Alerts) |

---

## What changed from the previous 7-module outline

The video course was originally organized into 7 modules (exam overview, cloud concepts, core services, management tools, security, pricing, practice exam) as a teaching sequence. That sequence still works for video pacing, but it doesn't match how Microsoft actually groups objectives — identity/security sits inside "architecture and services," not its own domain, and Microsoft's outline includes a full monitoring-tools objective (Azure Advisor, Service Health, Azure Monitor) that the old outline never covered.

This document reflects Microsoft's domains directly. The "Video module (legacy)" column above preserves the mapping so the existing Udemy course structure isn't orphaned — each video module still corresponds to one or more domains, it's just no longer the primary organizing structure.

## Gap topics (not exercised by any lab)

These sub-objectives aren't exercised by any existing lab — AZ-900 is a knowledge-only exam, and these are covered conceptually in the video course rather than by adding new hands-on labs:

- Microsoft Entra ID specifics (SSO, MFA, passwordless, Conditional Access, external identities)
- Zero Trust
- Microsoft Purview
- Azure Arc
- Azure Migrate, Azure Data Box
- Azure Advisor, Azure Service Health (Azure Monitor itself now has a hands-on lab: Lab 7)

## Open items before recording

- [ ] Re-confirm current domain weightings and skills outline against the live Microsoft AZ-900 study guide (link above) immediately before recording
- [ ] Sanity-check all Bicep API versions in `../labs/` against Microsoft Learn again close to publish date — see each lab's README for a direct link
- [ ] Storyboard/slide deck per video module — not yet started
