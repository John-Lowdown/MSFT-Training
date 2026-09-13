# AZ-900 Course Outline (7 Modules)

Working outline for the Udemy course. Each module lists its exam-guide domain, learning objectives, and the lab/walkthrough that reinforces it. Video length estimates are placeholders — refine once scripts exist.

---

## Module 1 — Exam Overview & Scoring
**Est. length:** 15–20 min | **Lab/walkthrough:** none (orientation module)

- What AZ-900 covers and what it deliberately doesn't (it's a fundamentals exam, not an associate-level exam — no deep hands-on config is tested)
- Exam format: number of questions, time limit, passing score, question types (multiple choice, drag-and-drop, case studies)
- How Microsoft weights the four domains (cloud concepts; Azure architecture & services; management & governance; pricing & support) — pull current weighting from the official exam skills outline before recording, since Microsoft revises these periodically
- Registration logistics, retake policy, what's on the Pearson VUE/online proctoring checklist
- How to use this course: watch → lab → practice questions, per module

## Module 2 — Cloud Concepts
**Est. length:** 45–60 min | **Lab/walkthrough:** conceptual only; referenced by Labs 1, 2, 3, 6

- Shared responsibility model (what Microsoft manages vs. what the customer manages, and how that split moves across IaaS/PaaS/SaaS)
- CapEx vs. OpEx, and why "pay for what you use" is the core economic argument for cloud
- Economies of scale
- Cloud deployment models: public, private, hybrid
- Consumption-based pricing model
- Scalability (scale up/out) vs. elasticity vs. high availability vs. fault tolerance vs. disaster recovery — these five terms get conflated constantly and are worth a dedicated comparison table on screen

## Module 3 — Core Azure Services
**Est. length:** 90–120 min | **Lab/walkthrough:** Labs 2 (Storage), 3 (Networking), 6 (App Service)

- Compute options: VMs, VM Scale Sets, App Service, Azure Functions, Container Instances, AKS — when to reach for each
- Networking fundamentals: VNets, subnets, NSGs, VPN Gateway, ExpressRoute, load balancers, Azure DNS
- Storage: storage account types, redundancy tiers (LRS/ZRS/GRS/GZRS), blob access tiers (hot/cool/archive)
- Databases: Azure SQL Database, Cosmos DB, when managed database services beat "a database on a VM"
- Azure Marketplace and resource deployment methods (Portal, CLI, PowerShell, ARM/Bicep templates) — light touch, Module 4 goes deeper

## Module 4 — Azure Management Tools
**Est. length:** 45–60 min | **Lab/walkthrough:** all six labs demonstrate CLI + Bicep directly

- Azure Portal tour
- Azure CLI and Cloud Shell
- Azure PowerShell (mention only — course leans CLI/Bicep for hands-on)
- ARM templates vs. Bicep — why this course teaches Bicep (readability, native tooling, still compiles to ARM JSON under the hood)
- Azure Resource Manager: resources, resource groups, subscriptions, management groups — the four-level scope hierarchy, tied directly back to Lab 1 and Lab 4's `targetScope` usage
- Azure Mobile App, Azure Advisor (brief mentions)

## Module 5 — Security, Privacy, Compliance
**Est. length:** 60–75 min | **Lab/walkthrough:** Lab 3 (NSGs), Lab 4 (RBAC)

- Defense in depth model
- Azure Active Directory (Microsoft Entra ID) fundamentals: identities, authentication vs. authorization, MFA, Conditional Access (conceptual)
- RBAC vs. Azure Policy — the distinction seeded in Lab 4, made explicit here
- Network security: NSGs, Azure Firewall, DDoS Protection (conceptual)
- Azure Security Center / Microsoft Defender for Cloud, Secure Score (conceptual)
- Compliance: Microsoft's compliance offerings, Trust Center, Azure Government (awareness-level only — AZ-900 doesn't expect deep compliance-framework knowledge)

## Module 6 — Pricing & SLAs
**Est. length:** 45–60 min | **Lab/walkthrough:** Lab 5 (Budgets)

- Factors affecting cost: resource type, region, bandwidth, licensing
- Pricing Calculator vs. TCO Calculator — different tools, different moments (before deployment vs. comparing to on-prem)
- Azure Cost Management: budgets, alerts, cost analysis — direct callback to Lab 5
- Service Level Agreements: how Azure defines and publishes SLAs per service, composite SLAs when chaining services, SLA credits
- Service lifecycle: Public Preview vs. GA vs. deprecated, and where to check current status

## Module 7 — Full Practice Exam + Explanations
**Est. length:** 90+ min | **Lab/walkthrough:** none (assessment module)

- 60–70 question full-length practice exam mirroring the real AZ-900 format and domain weighting
- Explanation video (or per-question written explanations) for every question, cross-referenced back to the module that covers it
- Guidance on interpreting a practice score against the real passing threshold
- "What's next" — the AZ-104 → AZ-305 upsell path, framed as a natural continuation rather than a hard sell

---

## Open items before recording

- [ ] Re-confirm current domain weightings and exam format against the live Microsoft AZ-900 exam page (Microsoft revises these — check immediately before recording Module 1)
- [ ] Sanity-check all Bicep API versions in `labs/` against Microsoft Learn again close to publish date — see each lab's README for a direct link
- [ ] Decide on practice-exam question bank size beyond the 60–70 in Module 7 (a rotating pool reduces the "answers get shared online" problem)
- [ ] Storyboard/slide deck per module — not yet started
