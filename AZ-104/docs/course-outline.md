# AZ-104 Course Outline (7 Modules)

Working outline for the AZ-104 (Microsoft Certified: Azure Administrator Associate) exam-prep course/book — built to the same standard and format as the AZ-900 course outline in this repo. Each module lists its exam-guide domain, learning objectives, source Microsoft Learn modules (linked as supplemental training, per the AZ-900 pattern), and the lab/walkthrough that exercises it hands-on.

**Aligned against Microsoft's official curriculum, September 2026:** this outline was cross-checked against the live [AZ-104 study guide, skills measured as of April 17, 2026](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104), all six official AZ-104 Microsoft Learn training paths (32 modules total), and — for Module 6 (monitoring) only — the official AZ-1004 "Deploy and configure Azure Monitor" Applied Skills trainer materials supplied during drafting, used strictly as a gap-analysis reference the way the AZ-900 outline used the MOC AZ-900T00A trainer PDFs — for topic/terminology coverage and structure, never as copied slide text, images, or exact wording. See "A note on scope" and "Alignment notes" below for what that means in practice and what changed as a result.

---

## A note on scope: AZ-104 vs. AZ-1004

Before this outline was drafted, a scope check turned up a real mismatch worth recording here so it isn't rediscovered later: the trainer materials referenced during drafting are for **AZ-1004: Deploy and configure Azure Monitor**, a separate, narrow one-day Microsoft "Applied Skills" credential — not part of the AZ-104 Administrator Associate exam family at all. AZ-1004 covers Log Analytics workspaces, Application Insights, VM monitoring agents/data collection rules, VNet *monitoring* (Network Watcher, Connection Monitor, IP flow verify, packet capture), and alerting — in much greater depth than AZ-104 needs, since AZ-104's "Monitor and maintain Azure resources" domain is only 10–15% of one broader exam.

Decision for this course: build the **full AZ-104 Administrator Associate curriculum** (all five weighted skill domains, matching this repo's AZ-900 → AZ-104 → AZ-305 progression), and use the AZ-1004 materials only as a **depth reference for Module 6** (monitoring), since that's the one place their subject matter genuinely overlaps with an AZ-104 skill area. They are not used for anything networking-related, despite one AZ-1004 section also being titled "Configure monitoring for virtual networks" — that section is about *monitoring* a VNet (topology maps, connection tests, packet capture), not *configuring* one (subnets, NSGs, peering, routing, load balancing), which is what AZ-104 Module 5 and the real "Configure and manage virtual networks" Learn path actually test.

---

## Module 1 — Exam Overview, Prerequisites & Administrator Tooling
**Est. length:** 20–25 min | **Lab/walkthrough:** none (orientation module)

- What AZ-104 covers and who it's for: the Microsoft Certified: Azure Administrator Associate credential — implementing, managing, and monitoring identity, governance, storage, compute, and virtual networks. Contrast with AZ-900 (fundamentals, no hands-on) and preview AZ-305 (architect-level, design rather than operate) to frame the certification progression this course sits in.
- Exam format: AZ-104, passing score 700 (Microsoft's 100–1000 scale), proctored via Pearson VUE; Microsoft does not publish an exact question count or duration on the public study guide — say so plainly rather than quoting a number, and confirm current timing/format directly on the exam scheduling page immediately before recording, since this is one of the details Microsoft updates without notice.
- **Skills measured as of April 17, 2026** — five weighted domains (verified against the live study guide, not carried over from an older version):

  | Domain | Weight | Labs |
  |---|---|---|
  | Manage Azure identities and governance | 20–25% | Labs 1–3 |
  | Implement and manage storage | 15–20% | Labs 4–5 |
  | Deploy and manage Azure compute resources | 20–25% | Labs 6–9 |
  | Implement and manage virtual networking | 15–20% | Labs 10–12 |
  | Monitor and maintain Azure resources | 10–15% | Labs 13–14 |

- Audience profile / assumed background per Microsoft's own guide: operating systems, networking, servers, virtualization familiarity, plus hands-on experience with PowerShell, Azure CLI, the Azure portal, and ARM templates or Bicep files. This course doesn't re-teach general IT fundamentals — it assumes them, unlike AZ-900.
- **Administrator tooling primer** (from the official [AZ-104: Prerequisites for Azure administrators](https://learn.microsoft.com/en-us/training/paths/az-104-administrator-prerequisites/) learning path — not itself a weighted exam domain, but load-bearing for every later module's demos):
  - [Manage services with the Azure portal](https://learn.microsoft.com/training/modules/tour-azure-portal/)
  - [Introduction to Azure Cloud Shell](https://learn.microsoft.com/training/modules/intro-to-azure-cloud-shell/)
  - [Introduction to Bash](https://learn.microsoft.com/training/modules/bash-introduction/)
  - [Introduction to PowerShell](https://learn.microsoft.com/training/modules/introduction-to-powershell/)
  - [Deploy Azure infrastructure by using JSON ARM templates](https://learn.microsoft.com/training/modules/create-azure-resource-manager-template-vs-code/)
- Registration logistics, retake policy, renewal (Azure Administrator Associate certifications expire after 12 months and renew via a free online assessment)
- How to use this course: watch/read → lab → practice questions, per module — same rhythm as the AZ-900 course

## Module 2 — Manage Azure Identities and Governance (20–25%)
**Est. length:** 90–110 min | **Lab/walkthrough:** [Lab 1](../labs/01-custom-rbac-scope/) (custom RBAC roles & scope hierarchy, extends AZ-900 Lab 4), [Lab 2](../labs/02-azure-policy-initiatives/) (policy initiatives & remediation, extends AZ-900 Lab 8), [Lab 3](../labs/03-governance-tags-cost/) (locks, budgets & resource moves, extends AZ-900 Labs 5 and 7)

Structured on the exam's own three sub-objectives:

**Manage Microsoft Entra users and groups**
- Create users and groups (including bulk creation patterns)
- Manage user and group properties, group types (security vs. Microsoft 365) and membership rules (assigned vs. dynamic)
- Manage licenses in Microsoft Entra ID
- Manage external users (B2B guest access — administering it, vs. AZ-900's conceptual-only treatment)
- Configure self-service password reset (SSPR) — setup, registration requirements, verification methods

**Manage access to Azure resources**
- Manage built-in Azure roles vs. custom roles (know when a built-in role is insufficient) — **Lab 1**
- Assign roles at different scopes (management group, subscription, resource group, resource) and understand inheritance — **Lab 1**
- Interpret access assignments — reading the "who has access" view and effective permissions, not just assigning them — **Lab 1**

**Manage Azure subscriptions and governance**
- Implement and manage Azure Policy (definitions, initiatives, assignments, compliance evaluation, remediation) — **Lab 2**
- Configure resource locks (`CanNotDelete` / `ReadOnly`) — direct callback to AZ-900 Lab 7, extended in **Lab 3**
- Apply and manage tags on resources (including tag policies/enforcement) — **Lab 2**
- Manage resource groups (move resources, delete, nested-resource implications) — **Lab 3**
- Manage subscriptions (offer types, moving resources across subscriptions) — **Lab 3**
- Manage costs using alerts, budgets, and Azure Advisor cost recommendations — direct callback to AZ-900 Lab 5, extended in **Lab 3**
- Configure management groups (the scope level above subscriptions — new territory versus AZ-900, which only described the hierarchy conceptually) — **Lab 1** (read-only portal tour)

**Source Microsoft Learn modules** ([AZ-104: Manage identities and governance in Azure](https://learn.microsoft.com/en-us/training/paths/az-104-manage-identities-governance/)):
- [Understand Microsoft Entra ID](https://learn.microsoft.com/training/modules/understand-azure-active-directory/)
- [Create, configure, and manage identities](https://learn.microsoft.com/training/modules/create-configure-manage-identities/)
- [Describe the core architectural components of Azure](https://learn.microsoft.com/training/modules/describe-core-architectural-components-of-azure/)
- [Azure Policy initiatives](https://learn.microsoft.com/en-us/training/modules/sovereignty-policy-initiatives/)
- [Secure your Azure resources with Azure RBAC](https://learn.microsoft.com/training/modules/secure-azure-resources-with-rbac/)
- [Allow users to reset their password with Microsoft Entra self-service password reset](https://learn.microsoft.com/training/modules/allow-users-reset-their-password/)

**Coverage gap closed by this repo's labs:** resource locks, tags, cost-management alerts/budgets/Advisor, and management-group configuration are all explicit exam sub-bullets with no dedicated Learn module — Labs 1–3 close that gap with direct hands-on exercises rather than relying on "core architectural components"'s glancing coverage.

## Module 3 — Implement and Manage Storage (15–20%)
**Est. length:** 70–90 min | **Lab/walkthrough:** [Lab 4](../labs/04-storage-security-access/) (SAS, network rules & CMK encryption) and [Lab 5](../labs/05-storage-lifecycle-protection/) (lifecycle management, versioning & object replication) — both extend AZ-900 Lab 2 to configuration/security depth

**Configure access to storage**
- Configure Azure Storage firewalls and virtual network rules — **Lab 4**
- Create and use shared access signature (SAS) tokens (account SAS vs. service SAS vs. user delegation SAS) — **Lab 4**
- Configure stored access policies — **Lab 4**
- Manage storage account access keys (rotation, regeneration) — **Lab 4**
- Configure identity-based (Entra ID) access for Azure Files

**Configure and manage storage accounts**
- Create and configure storage accounts (performance tiers, account kinds)
- Configure Azure Storage redundancy (LRS/ZRS/GRS/GZRS — direct callback to AZ-900 Lab 2, now taught at configuration depth)
- Configure object replication (cross-account, cross-region) — **Lab 5**
- Configure storage account encryption (Microsoft-managed vs. customer-managed keys) — **Lab 4**
- Manage data using Azure Storage Explorer and AzCopy

**Configure Azure Files and Azure Blob Storage**
- Create and configure a file share in Azure Files; Azure File Sync — **Lab 5**
- Create and configure a container in Azure Blob Storage
- Configure storage/access tiers (hot/cool/cold/archive) — **Lab 5**
- Configure soft delete for blobs, containers, and file shares; snapshots — **Lab 5**
- Configure blob lifecycle management (automated tiering/deletion policies) — **Lab 5**
- Configure blob versioning — **Lab 5**

**Source Microsoft Learn modules** ([AZ-104: Implement and manage storage in Azure](https://learn.microsoft.com/en-us/training/paths/az-104-manage-storage/)):
- [Configure storage accounts](https://learn.microsoft.com/training/modules/configure-storage-accounts/)
- [Configure Azure Blob Storage](https://learn.microsoft.com/training/modules/configure-blob-storage/)
- [Configure Azure Storage security](https://learn.microsoft.com/training/modules/configure-storage-security/)
- [Configure Azure Files](https://learn.microsoft.com/training/modules/configure-azure-files-file-sync/)

## Module 4 — Deploy and Manage Azure Compute Resources (20–25%)
**Est. length:** 100–120 min | **Lab/walkthrough:** [Lab 6](../labs/06-vm-availability-disks/) (VM deployment, zones & managed disks, extends AZ-900 Lab 9), [Lab 7](../labs/07-vmss-autoscale/) (scale sets & autoscale), [Lab 8](../labs/08-containers-acr-aci-apps/) (ACR, Container Instances & Container Apps), [Lab 9](../labs/09-app-service-advanced/) (App Service slots & VNet integration, extends AZ-900 Lab 6)

**Automate deployment with ARM templates or Bicep files**
- Interpret an ARM template or Bicep file; modify an existing one of each
- Deploy resources using an ARM template or Bicep file
- Export a deployment as an ARM template, or convert an ARM template to Bicep
- Direct callback to this course's own Bicep-first labs (already used throughout the AZ-900 course and continued in every AZ-104 lab) and to Module 1's ARM-template prerequisite module

**Create and configure virtual machines**
- Create a VM (sizing, images, disk options) — **Lab 6**
- Configure encryption at host — **Lab 6**
- Move a VM to another resource group, subscription, or region — **Lab 6**
- Manage VM sizes (resizing considerations/downtime) — **Lab 6**
- Manage VM disks (OS vs. data disks, managed disks, disk types) — **Lab 6**
- Deploy VMs to availability zones and availability sets — and the distinction between the two — **Lab 6**
- Deploy and configure Azure Virtual Machine Scale Sets — **Lab 7**

**Provision and manage containers**
- Create and manage an Azure Container Registry — **Lab 8**
- Provision a container using Azure Container Instances — **Lab 8**
- Provision a container using Azure Container Apps — **Lab 8**
- Manage sizing and scaling for both Container Instances and Container Apps — **Lab 8**

**Create and configure Azure App Service**
- Provision an App Service plan; configure scaling for it — **Lab 9**
- Create an App Service — **Lab 9**
- Configure certificates and TLS for an App Service — **Lab 9** (manual task — requires an owned domain)
- Map an existing custom DNS name to an App Service — **Lab 9** (manual task)
- Configure backup for an App Service — **Lab 9** (manual task)
- Configure networking settings for an App Service (VNet integration, private endpoints — ties forward to Module 5) — **Lab 9**
- Configure deployment slots — **Lab 9**

**Source Microsoft Learn modules** ([AZ-104: Deploy and manage Azure compute resources](https://learn.microsoft.com/en-us/training/paths/az-104-manage-compute-resources/)):
- [Introduction to Azure virtual machines](https://learn.microsoft.com/training/modules/intro-to-azure-virtual-machines/)
- [Configure virtual machine availability](https://learn.microsoft.com/training/modules/configure-virtual-machine-availability/)
- [Configure Azure App Service plans](https://learn.microsoft.com/training/modules/configure-app-service-plans/)
- [Configure Azure App Service](https://learn.microsoft.com/training/modules/configure-azure-app-services/)
- [Configure Azure Container Instances](https://learn.microsoft.com/training/modules/configure-azure-container-instances/)

**Coverage gap closed by this repo's labs:** Container Registry and Container Apps are named exam sub-bullets the Learn path's container module doesn't reach (it only covers Container Instances) — Lab 8 builds all three side by side.

## Module 5 — Implement and Manage Virtual Networking (15–20%)
**Est. length:** 110–130 min | **Lab/walkthrough:** [Lab 10](../labs/10-vnet-peering-routing/) (peering & UDRs), [Lab 11](../labs/11-nsg-asg-bastion-endpoints/) (NSGs, ASGs, Bastion & private endpoints, extends AZ-900 Lab 3), [Lab 12](../labs/12-load-balancer-dns/) (Standard Load Balancer & Azure DNS)

**Configure and manage virtual networks in Azure**
- Create and configure virtual networks and subnets, including IP addressing — **Lab 10**
- Create and configure virtual network peering (transit and connectivity considerations) — **Lab 10**
- Configure public IP addresses (SKUs, allocation methods) — **Lab 10**
- Configure user-defined routes — **Lab 10**
- Troubleshoot network connectivity

**Configure secure access to virtual networks**
- Create and configure network security groups (NSGs) and application security groups; evaluate effective security rules — direct callback to AZ-900 Lab 3, extended in **Lab 11**
- Implement Azure Bastion — **Lab 11**
- Configure service endpoints for Azure PaaS
- Configure private endpoints for Azure PaaS (ties back to Module 4's App Service networking settings) — **Lab 11**

**Configure name resolution and load balancing**
- Configure Azure DNS (public/private zones, records) — **Lab 11** (private zone), **Lab 12** (public zone)
- Configure an internal or public load balancer — **Lab 12**
- Troubleshoot load balancing

**Source Microsoft Learn modules** ([AZ-104: Configure and manage virtual networks for Azure administrators](https://learn.microsoft.com/en-us/training/paths/az-104-manage-virtual-networks/)):
- [Configure virtual networks](https://learn.microsoft.com/training/modules/configure-virtual-networks/)
- [Configure network security groups](https://learn.microsoft.com/training/modules/configure-network-security-groups/)
- [Host your domain on Azure DNS](https://learn.microsoft.com/training/modules/host-domain-azure-dns/)
- [Configure Azure Virtual Network peering](https://learn.microsoft.com/training/modules/configure-vnet-peering/)
- [Manage and control traffic flow in your Azure deployment with routes](https://learn.microsoft.com/training/modules/control-network-traffic-flow-with-routes/)
- [Introduction to Azure Load Balancer](https://learn.microsoft.com/training/modules/intro-to-azure-load-balancer/)
- [Introduction to Azure Application Gateway](https://learn.microsoft.com/training/modules/intro-to-azure-application-gateway/)
- [Introduction to Azure Network Watcher](https://learn.microsoft.com/training/modules/intro-to-azure-network-watcher/) *(orientation only here — full Network Watcher configuration and Connection Monitor content lives in Module 6, since that's where the exam actually tests it)*

**Terminology comparison (supporting, not a separate exam bullet, but easy to conflate):**
- Service endpoint vs. private endpoint — what traffic path each secures and when to use which (**Lab 11** makes the private-endpoint half concrete)
- Network security group vs. application security group vs. Azure Firewall (AZ-900-level awareness only; Firewall itself isn't an AZ-104 sub-bullet)
- Load Balancer vs. Application Gateway — OSI layer, use case, and why the exam tests both as separate services (**Lab 12** covers Load Balancer; Application Gateway has no dedicated lab in this repo yet)

**Coverage gap closed by this repo's labs:** Azure Bastion and private endpoints are named exam sub-bullets without a standalone module in this Learn path — Lab 11 builds both directly.

## Module 6 — Monitor and Maintain Azure Resources (10–15%)
**Est. length:** 70–90 min | **Lab/walkthrough:** [Lab 13](../labs/13-monitor-log-analytics/) (Log Analytics, diagnostic settings & KQL, extends AZ-900 Lab 7), [Lab 14](../labs/14-backup-recovery/) (Recovery Services vault, VM backup/restore & optional Site Recovery)

**Monitor resources in Azure**
- Interpret metrics in Azure Monitor — direct callback to AZ-900 Lab 7
- Configure log settings (diagnostic settings → Log Analytics workspace) — **Lab 13**
- Query and analyze logs in Azure Monitor (Kusto Query Language / KQL) — **Lab 13**
- Set up alert rules, action groups, and alert processing rules — **Lab 13**
- Configure and interpret monitoring of VMs, storage accounts, and networks using Azure Monitor Insights
- Use Azure Network Watcher and Connection Monitor (the configuration depth that Module 5's orientation-only Network Watcher module doesn't cover) — **Lab 13** (manual task)

**Implement backup and recovery**
- Create a Recovery Services vault vs. an Azure Backup vault — when each applies — **Lab 14**
- Create and configure a backup policy — **Lab 14**
- Perform backup and restore operations using Azure Backup — **Lab 14** (manual task)
- Configure Azure Site Recovery for Azure resources — **Lab 14** (optional, manual, capstone-style)
- Perform a failover to a secondary region using Site Recovery — **Lab 14** (optional, manual, capstone-style)
- Configure and interpret reports and alerts for backups

**Source Microsoft Learn modules** ([AZ-104: Monitor and back up Azure resources](https://learn.microsoft.com/en-us/training/paths/az-104-monitor-backup-resources/)):
- [Introduction to Azure Backup](https://learn.microsoft.com/training/modules/intro-to-azure-backup/)
- [Protect your virtual machines by using Azure Backup](https://learn.microsoft.com/training/modules/protect-virtual-machines-with-azure-backup/)
- [Introduction to Azure Monitor](https://learn.microsoft.com/training/modules/intro-to-azure-monitor/)
- [Improve incident response with Azure Monitor alerts](https://learn.microsoft.com/training/modules/incident-response-with-alerting-on-azure/)

**Supplemental reference for this module only — AZ-1004 trainer materials (topic/structure reference, not copied content):** Log Analytics workspace creation, data retention tiers, and workspace RBAC; KQL query patterns (simple mode vs. KQL mode); Azure Monitor Agent + Data Collection Rules; Network Watcher topology/Connection Monitor/IP flow verify/packet capture; and alert rule/action group anatomy all map directly onto named AZ-104 Module 6 sub-bullets and informed Lab 13's scope. Application Insights, also prominent in the AZ-1004 deck, has no corresponding AZ-104 sub-bullet and gets at most a brief mention.

**Coverage gap closed by this repo's labs:** Log Analytics/KQL and the Recovery Services vault's hard-delete-blocking behavior (no dedicated Learn module covers the latter) are both exercised directly in Labs 13–14. Azure Site Recovery and failover remain the one sub-bullet this repo treats as optional/manual-only rather than a routine repeatable lab, given the cost and cross-region setup involved — see Lab 14's README for why.

## Module 7 — Full Practice Exam + Wrap-Up
**Est. length:** 90+ min | **Lab/walkthrough:** none (assessment module); optional capstone exercise

- 60–70 question full-length practice exam mirroring AZ-104's format and the current 20-25/15-20/20-25/15-20/10-15 domain weighting (proportionally more questions on identity/governance and compute than on monitoring, matching the real exam's emphasis)
- Explanation for every question, cross-referenced back to the module (2–6) that covers it
- Guidance on interpreting a practice score against the real 700 passing threshold
- "What's next" — continuing to AZ-305 (architect-level design), framed as a natural continuation, matching this repo's existing AZ-900 → AZ-104 → AZ-305 progression note
- Optional capstone-style scenario exercise: "stand up a hub-and-spoke VNet with peering and NSGs (Labs 10–11), deploy a VM Scale Set behind a load balancer (Labs 7, 12), lock down storage with a private endpoint (Lab 11) and customer-managed keys (Lab 4), and configure monitoring + backup for the whole environment (Labs 13–14)" — since that single scenario touches all five AZ-104 domains the way a real admin task would, and every piece of it is something this repo's labs already built individually

---

## Labs and walkthroughs built

All 14 labs are built — see [`../labs/`](../labs/) for the Bicep + README pairs and [`../walkthroughs/`](../walkthroughs/) for the matching portal-first walkthroughs. Every lab's README states its real cost plainly; several Module 4/5 labs are genuinely billable by the hour (VMs, App Service Standard tier, Azure Bastion) unlike most of the AZ-900 course — clean up promptly after each demo.

## Open items before recording video content

- [x] Domain weightings and exam format verified against Microsoft's official study guide (April 17, 2026 revision, checked September 2026).
- [x] All 32 modules across the six official AZ-104 Learn paths enumerated and mapped to the five weighted exam domains.
- [x] Scope conflict between the AZ-1004 trainer materials and AZ-104's actual curriculum identified and resolved — see "A note on scope" above.
- [x] All 14 hands-on labs built (Bicep + README + portal walkthrough each) — see "Labs and walkthroughs built" above.
- [ ] Pull full unit-level content (text, diagrams, knowledge-check questions) from all 32 Learn modules for the actual chapter drafts and to source diagrams for a `Learn Images/` folder, the way AZ-900's `Learn Images/` was built — not yet started.
- [ ] Confirm current AZ-104 exam duration/question count directly on the Pearson VUE scheduling page immediately before publishing — the public study guide doesn't state either.
- [ ] Practice-exam question bank (Module 7) — not yet started; should mirror the AZ-900 bank's domain-weighted approach, reweighted 20-25/15-20/20-25/15-20/10-15.
- [ ] Optional capstone exercise (Module 7) — scenario sketched above, not yet drafted or tested end-to-end as one continuous deployment.
- [ ] Video/lecture scripts — not yet started.
- [ ] Sanity-check all Bicep API versions in `../labs/` against Microsoft Learn again close to publish date — see each lab's README for a direct link.

---

## Alignment notes (September 2026 review against official Microsoft materials)

**Sources checked:**
- [AZ-104 study guide, skills measured as of April 17, 2026](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-104) — the authoritative domain list, weightings, and sub-bullets this whole outline is built from.
- [Microsoft Certified: Azure Administrator Associate](https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/) certification page — confirms 12-month renewal and "Last Updated 04/17/2026," consistent with the study guide.
- All six official AZ-104 Microsoft Learn training paths (Prerequisites, Identities & Governance, Storage, Compute, Virtual Networks, Monitor & Backup) — 32 modules total, enumerated above.
- The AZ-1004 "Deploy and configure Azure Monitor" Trainer Prep Guide and its three PowerPoint decks, used only for Module 6, only for topic/structure gap-checking, per "A note on scope" above.

**What this review found (real content gaps between the Learn paths and the official exam skill list, not present in either the Learn modules or, where checked, the AZ-1004 materials) — and how this repo's labs close each one:**
- Module 2: resource locks, resource tagging, cost-management alerts/budgets/Advisor recommendations, and management-group configuration are named exam sub-bullets with no dedicated Learn module — closed by Labs 1–3.
- Module 4: Azure Container Registry and Azure Container Apps are named exam sub-bullets; the compute path's only container module covers Container Instances alone — closed by Lab 8.
- Module 5: Azure Bastion, service endpoints, and private endpoints for Azure PaaS are named exam sub-bullets with no dedicated module in the 8-module networking path — closed by Lab 11 (Bastion, private endpoints); service endpoints remain conceptual-only for now.
- Module 6: Azure Site Recovery and cross-region failover are named exam sub-bullets absent from both the 4-module Learn path and the AZ-1004 materials — Lab 14 covers this as an explicitly optional, manual-only capstone section rather than a routine repeatable exercise, given the real cost and cross-region setup involved.

**Where the AZ-1004 materials genuinely added value (Module 6 only):** Log Analytics workspace configuration/retention/RBAC, KQL query patterns, and alert rule/action group anatomy map directly onto named AZ-104 Module 6 sub-bullets and shaped Lab 13's scope. Application Insights, also prominent in the AZ-1004 deck, has no corresponding AZ-104 sub-bullet and was deliberately left out of Lab 13.

**Considered and deliberately not adopted:**
- Using the AZ-1004 Network Watcher content (topology, Connection Monitor, packet capture) for Module 5 instead of Module 6 — rejected, because the exam's own skill list places "Use Azure Network Watcher and Connection Monitor" under "Monitor and maintain Azure resources" (Module 6), not under "Implement and manage virtual networking" (Module 5), even though it's easy to assume otherwise since Network Watcher is a networking tool. Module 5's labs (10–12) keep Network Watcher out of scope entirely; Lab 13 picks it up as a manual task.
- Copying AZ-1004 slide text, screenshots, or exact demo steps directly — these are Microsoft's copyrighted MOC/Applied Skills trainer materials; they're used here only to identify which topics and terms to cover and in what depth, the same arm's-length approach the AZ-900 outline took with the AZ-900T00A trainer PDFs.
