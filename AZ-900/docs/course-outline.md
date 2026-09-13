# AZ-900 Skills Alignment (3 Domains)

Master alignment map for this repo's AZ-900 book and video course, matching Microsoft's official skills-measured outline for Exam AZ-900 (per the [official study guide](https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-900), skills as of July 20, 2026). Both the book (`../book/manuscript/`) and the video course walk through this same structure — this document is the single source of truth for what maps to what.

> **Re-confirm before recording/publishing.** Microsoft revises the skills outline and domain weightings periodically — check the live study guide link above immediately before recording new video content or finalizing the book for sale.

---

## Domain 1 — Describe cloud concepts (25–30%)

| Sub-objective | Book chapter | Video module (legacy) | Lab/walkthrough |
|---|---|---|---|
| Describe cloud computing | [Ch 1](../book/manuscript/01-cloud-computing.md) | Module 2 (Cloud Concepts) | — |
| Describe the benefits of using cloud services | [Ch 2](../book/manuscript/02-cloud-benefits.md) | Module 2 | — |
| Describe cloud service types (IaaS/PaaS/SaaS) | [Ch 3](../book/manuscript/03-cloud-service-types.md) | Module 2 / Module 3 | Lab 6 (App Service) |

## Domain 2 — Describe Azure architecture and services (35–40%)

| Sub-objective | Book chapter | Video module (legacy) | Lab/walkthrough |
|---|---|---|---|
| Core architectural components of Azure | [Ch 4](../book/manuscript/04-core-architecture.md) | Module 4 (Management Tools) | Lab 1 (Resource Groups & Tagging) |
| Azure compute and networking services | [Ch 5](../book/manuscript/05-compute-networking.md) | Module 3 (Core Azure Services) | Lab 3 (VNet & NSG), Lab 6 (App Service) |
| Azure storage services | [Ch 6](../book/manuscript/06-storage-services.md) | Module 3 | Lab 2 (Storage Redundancy) |
| Azure identity, access, and security | [Ch 7](../book/manuscript/07-identity-access-security.md) | Module 5 (Security, Privacy, Compliance) | Lab 3 (NSGs), Lab 4 (RBAC) |

## Domain 3 — Describe Azure management and governance (30–35%)

| Sub-objective | Book chapter | Video module (legacy) | Lab/walkthrough |
|---|---|---|---|
| Cost management in Azure | [Ch 8](../book/manuscript/08-cost-management.md) | Module 6 (Pricing & SLAs) | Lab 5 (Budgets & Cost Alerts), Pricing/TCO Calculator walkthrough |
| Governance and compliance tools | [Ch 9](../book/manuscript/09-governance-compliance.md) | Module 5 | Lab 1 (Tagging), Lab 4 (RBAC) |
| Managing and deploying Azure resources | [Ch 10](../book/manuscript/10-managing-deploying-resources.md) | Module 4 | All 6 labs (CLI/Bicep); Portal-vs-CLI-vs-Bicep walkthrough |
| Monitoring tools in Azure | [Ch 11](../book/manuscript/11-monitoring-tools.md) | *(not previously covered)* | — (conceptual only) |

---

## What changed from the previous 7-module outline

The video course was originally organized into 7 modules (exam overview, cloud concepts, core services, management tools, security, pricing, practice exam) as a teaching sequence. That sequence still works for video pacing, but it doesn't match how Microsoft actually groups objectives — identity/security sits inside "architecture and services," not its own domain, and Microsoft's outline includes a full monitoring-tools objective (Azure Advisor, Service Health, Azure Monitor) that the old outline never covered.

This document now reflects Microsoft's domains directly. The "Video module (legacy)" column above preserves the mapping so the existing Udemy course structure isn't orphaned — each video module still corresponds to one or more book chapters, it's just no longer the primary organizing structure.

## Gap topics (new in this alignment, conceptual-only in the book)

These sub-objectives aren't exercised by any existing lab — AZ-900 is a knowledge-only exam, so the book covers them in prose rather than adding new hands-on labs:

- Microsoft Entra ID specifics (SSO, MFA, passwordless, Conditional Access, external identities) — Chapter 7
- Zero Trust — Chapter 7
- Microsoft Purview — Chapter 9
- Azure Arc — Chapter 10
- Azure Migrate, Azure Data Box — Chapter 6
- Azure Advisor, Azure Service Health, Azure Monitor/Log Analytics/Application Insights — Chapter 11

## Open items before publishing/recording

- [ ] Re-confirm current domain weightings and skills outline against the live Microsoft AZ-900 study guide (link above) immediately before recording or finalizing the book
- [ ] Sanity-check all Bicep API versions in `../labs/` against Microsoft Learn again close to publish date — see each lab's README for a direct link
- [ ] Draft remaining book chapters (2, 4–11) and both appendices (practice exam question bank, glossary) — see `../book/README.md` for current status
- [ ] Decide on practice-exam question bank size beyond the 60–70 baseline (a rotating pool reduces the "answers get shared online" problem)
- [ ] Storyboard/slide deck per video module — not yet started
