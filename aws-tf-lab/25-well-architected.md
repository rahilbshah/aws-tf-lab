---
topic: 25-well-architected
domain: secure
status: reviewed
services: [WellArchitectedTool, TrustedAdvisor]
related: [14-dr-resilience, 13-cost-optimization, 21-security, 20-monitoring, 24-other-services]
tags: [topic, domain/secure]
---

# 25 – Well-Architected Framework

The course calls this section "WhitePapers and Architectures". It isn't new services — it's the framework the **entire exam is structured around**, plus the two tools that measure against it.

> [!info] Exam TL;DR
> - **Six pillars:** Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, **Sustainability**. Six, not five — Sustainability is the newest.
> - **Four of them are the four exam domains:** Security (30%), Reliability (26%), Performance Efficiency (24%), Cost Optimization (20%). Operational Excellence and Sustainability have no domain of their own.
> - **Reliability ≠ Performance Efficiency.** Reliability = survives and recovers from failure. Performance = right resource, used efficiently.
> - **Well-Architected Tool** = **free**, console-based, question-driven review of a **workload**; extensible with **lenses** (AWS-provided or **custom**); integrates with Trusted Advisor.
> - **Trusted Advisor** = inspects **deployed resources**. **Six categories:** cost optimization, performance, security, fault tolerance, **service limits**, operational excellence.
> - **Basic/Developer Support** → all **Service Limits** checks plus a fixed handful of Security/Fault Tolerance checks (incl. **MFA on root account**, **S3 Bucket Permissions**, public EBS/RDS snapshots). **All checks require a paid support plan.**
> - **WA Tool = review the design. Trusted Advisor = inspect the resources. AWS Config = continuously evaluate and remediate.**
> - **Whitepapers** are the source of the exam's "best practice" answers — and they age; verify their numbers.

> [!warning] Build tier — **conceptual-only**
> The Well-Architected Tool is free and worth ten minutes clicking through in the console if you're curious. There is nothing to build.

## What problem does this solve?

Here's the thing that makes this section worth more than its question count suggests.

**The four exam domains are four of the six Well-Architected pillars.** Not loosely — directly:

| Exam domain | Weight | Pillar |
|---|---|---|
| Domain 1: Design **Secure** Architectures | **30%** | **Security** |
| Domain 2: Design **Resilient** Architectures | **26%** | **Reliability** |
| Domain 3: Design **High-Performing** Architectures | **24%** | **Performance Efficiency** |
| Domain 4: Design **Cost-Optimized** Architectures | **20%** | **Cost Optimization** |

That's my own mapping against the exam guide rather than something AWS states outright, but the correspondence is exact and it explains the shape of every question you've practised. When a scenario says *"the MOST cost-effective solution"* or *"the MOST secure"*, it is asking you to optimise one pillar — and the reason those questions have a single defensible answer is that the framework says which trade-offs are acceptable.

The two pillars that **don't** get their own domain are **Operational Excellence** and **Sustainability**. They still appear inside questions; they just aren't scored as a category.

So this section is worth twenty minutes for the framing alone, plus a handful of directly testable facts about Trusted Advisor and the WA Tool.

> In one line: the six pillars are the exam's skeleton — four of them are literally the four scored domains.

## How it actually works

### The six pillars

AWS's own ordering, and the one-line job of each:

| Pillar | The question it asks |
|---|---|
| **Operational Excellence** | Can we run, monitor and improve this? (automate changes, respond to events, define standards) |
| **Security** | Are data and systems protected? (confidentiality, integrity, permissions, detection) |
| **Reliability** | Does it do its job and recover from failure? |
| **Performance Efficiency** | Are we using compute resources efficiently, and staying efficient as demand and technology change? |
| **Cost Optimization** | Are we delivering business value at the lowest price point? |
| **Sustainability** | Are we minimising the environmental impact of running this? |

**Sustainability is the newest pillar**, which is why older course material and older practice questions say five. If a question asks how many pillars there are, the answer is **six**.

A distinction worth holding, because it's the one people get wrong: **Reliability and Performance Efficiency are not the same axis.** Reliability is *does it survive failure and recover* — that's the Multi-AZ, ASG, backup, DR material in [[14-dr-resilience]]. Performance Efficiency is *are we using the right resource for the job* — instance types, caching, the right database engine. A workload can be extremely reliable and badly inefficient, and vice versa.

> In one line: six pillars — operational excellence, security, reliability, performance efficiency, cost optimization, sustainability — and reliability ≠ performance.

### What a "whitepaper" actually is, and which ones matter

AWS whitepapers are first-party technical documents written by AWS solutions architects. They are where the exam's opinions come from — when a question has a "best practice" answer, a whitepaper usually said so first.

You've already used one: the **Disaster Recovery of Workloads on AWS** whitepaper is the source for the four DR strategies, the pilot-light-versus-warm-standby wording, and data plane versus control plane in [[14-dr-resilience]]. That's exactly how they function — not extra reading, but the origin of the answers.

The ones that matter for SAA-C03 are the **Well-Architected Framework** itself and its **Reliability** and **Security** pillar documents. You do not need to read them cover to cover; the vault notes already carry their conclusions.

One caution learned the hard way on the DR whitepaper: **whitepapers age.** That one was last revised in April 2022 and still says Aurora Global Database supports five secondary Regions when the current limit is ten. Treat a whitepaper as authoritative on *concepts* and verify its *numbers*.

> In one line: whitepapers are where the exam's "best practice" answers come from — trust their concepts, check their numbers.

### AWS Well-Architected Tool — the free self-assessment

The **AWS Well-Architected Tool** is a console service that walks you through the framework's questions for a given **workload** and reports where you're at risk. **It is available at no charge in the AWS Management Console.**

What it does: documents the decisions you've made, produces recommendations against best practices, and tracks improvement over time.

Two terms to recognise. A **lens** applies a specialised set of questions — there are AWS lenses (serverless, SaaS, financial services, machine learning) and **custom lenses** you write yourself to encode your own organisation's standards. It also **integrates with Trusted Advisor** so some review answers can be filled in from what's actually deployed.

> In one line: the WA Tool is a free, question-driven self-assessment of a workload against the pillars, extensible with lenses.

### AWS Trusted Advisor — the automated inspection

**Trusted Advisor** *"inspects your AWS environment, and then makes recommendations when opportunities exist to save money, improve system availability and performance, or help close security gaps."* Where the WA Tool asks you questions, Trusted Advisor **looks at what you've actually deployed**.

**Six check categories:**

| Category | Example of what it flags |
|---|---|
| **Cost optimization** | idle load balancers, underutilised instances |
| **Performance** | over-utilised instances, unrestricted CloudFront settings |
| **Security** | **MFA on root account**, public S3 buckets, open security group ports |
| **Fault tolerance** | no Multi-AZ, missing backups |
| **Service limits** | quota usage approaching the limit |
| **Operational Excellence** | operational best-practice gaps |

Note that six — **Operational Excellence was added later**, so older material saying "five categories" is out of date.

**The support-plan split is the classic exam fact.** With **Basic or Developer Support** you get **all checks in the Service Limits category**, plus a short fixed list in Security and Fault Tolerance: *EBS Public Snapshots, RDS Public Snapshots, S3 Bucket Permissions, MFA on root account, Security Groups – Specific Ports Unrestricted,* and *STS global endpoint usage*. **All** checks — plus the API and EventBridge integration — require a higher support plan.

> [!warning] Currency — the support plans are being restructured
> AWS documentation now states that **Developer, Business and Enterprise On-Ramp support plans will be discontinued on 1 January 2027**, replaced by **Business Support+**, and that full Trusted Advisor requires *"Business Support+, Enterprise Support, or Unified Operations"*. The exam still uses the old **Business / Enterprise** framing — answer with that, but know the tiers are moving.

> In one line: Trusted Advisor inspects what's deployed across six categories; Basic/Developer gets service limits plus a handful of security and fault-tolerance checks, everything else needs a paid plan.

### WA Tool vs Trusted Advisor vs Config — three things that "check your account"

These three get offered together and are genuinely different jobs:

- **Well-Architected Tool** — *you answer questions* about a workload's design. Subjective, architectural, point-in-time review.
- **Trusted Advisor** — *AWS inspects your resources* against a fixed set of best-practice checks. Objective, account-wide, advisory.
- **AWS Config** — *continuously records configuration and evaluates rules*, with history, drift detection and auto-remediation ([[20-monitoring]]). Continuous and enforceable.

"Continuously evaluate and remediate" is **Config**. "Am I over-provisioned / is root MFA on?" is **Trusted Advisor**. "Review this architecture against best practices" is the **WA Tool**.

> In one line: WA Tool reviews design, Trusted Advisor inspects resources, Config continuously evaluates and remediates.

## Key facts, limits & pricing

- **The AWS Well-Architected Framework has six pillars:** operational excellence, security, reliability, performance efficiency, cost optimization, and sustainability.
- **AWS Well-Architected Tool** provides *"a consistent process for measuring your architecture using AWS best practices"* — documenting decisions, recommending improvements, and guiding workloads to be more reliable, secure, efficient and cost-effective. It supports **custom lenses** encoding your own best practices, and **integrates with AWS Trusted Advisor and AWS Service Catalog AppRegistry** to help answer review questions. **Available at no charge in the AWS Management Console.**
- **AWS Trusted Advisor** *"inspects your AWS environment, and then makes recommendations when opportunities exist to save money, improve system availability and performance, or help close security gaps."*
- **Trusted Advisor check categories (6):** Cost optimization · Performance · Security · Fault tolerance · Service limits · Operational Excellence.
- **Trusted Advisor by support plan:** Basic and Developer Support get **all checks in the Service limits category**, plus exactly these — *Amazon EBS Public Snapshots, Amazon RDS Public Snapshots, Amazon S3 Bucket Permissions, MFA on root account, Security Groups – Specific Ports Unrestricted,* and *AWS STS global endpoint usage*. Automatic check updates are **not** available on Basic; Security-category checks must be refreshed manually. Full access (plus the **Trusted Advisor API** and **EventBridge** monitoring) requires a paid plan.
- **⚠️ Support-plan restructuring:** AWS documentation states **Developer Support, Business Support and Enterprise On-Ramp will be discontinued on 1 January 2027**, with **Business Support+** as the replacement tier, and that full Trusted Advisor now requires *Business Support+, Enterprise Support, or Unified Operations*. The exam's framing is still Business/Enterprise.
- **Exam structure:** SAA-C03 scored content is Domain 1 Design Secure Architectures **30%**, Domain 2 Design Resilient Architectures **26%**, Domain 3 Design High-Performing Architectures **24%**, Domain 4 Design Cost-Optimized Architectures **20%**, across **14 task statements**.

## Comparisons

### The six pillars, and where each lives in this vault

| Pillar | Core question | Exam domain | Vault |
|---|---|---|---|
| **Operational Excellence** | can we run and improve it? | **none** | [[20-monitoring]] |
| **Security** | is it protected? | **D1 — 30%** | [[21-security]], [[01-iam]] |
| **Reliability** | does it survive failure? | **D2 — 26%** | [[14-dr-resilience]] |
| **Performance Efficiency** | is it the right resource? | **D3 — 24%** | [[02-ec2]], [[08-elasticache]] |
| **Cost Optimization** | lowest price for the value? | **D4 — 20%** | [[13-cost-optimization]] |
| **Sustainability** | minimal environmental impact? | **none** | — |

### WA Tool vs Trusted Advisor vs AWS Config

|   | **Well-Architected Tool** | **Trusted Advisor** | **AWS Config** |
|---|---|---|---|
| What it examines | **your answers** about a workload's design | **deployed resources** | **resource configuration over time** |
| Mode | point-in-time **review** | ongoing **advisory checks** | **continuous** evaluation |
| Output | risks and improvement plan | recommendations in 6 categories | compliance status, **history**, remediation |
| Can enforce | ✗ | ✗ | **✓ (rules + SSM remediation)** |
| Cost | **free** | tiered by **support plan** | per configuration item / rule evaluation |
| Question signal | "review our architecture against best practices" | "MFA on root?", "idle resources?" | "continuously evaluate and **remediate**" |

## Worked examples

> [!example] Worked example — reading a question as a pillar question
> *"A company runs a reporting application on three m5.4xlarge instances behind an ALB. Utilisation averages 8%. What should a solutions architect recommend to reduce cost while maintaining availability?"*
> The phrase *"reduce cost while maintaining availability"* is naming two pillars and telling you which one wins. **Cost Optimization** is the objective; **Reliability** is the constraint you must not break. That immediately kills two families of answer: anything that saves money by dropping to a single instance or a single AZ violates the constraint, and anything that improves performance without reducing spend ignores the objective. What's left is right-sizing — smaller instances, more of them across AZs, or an ASG with a lower baseline — plus a purchase-commitment option like Savings Plans ([[13-cost-optimization]]). Reading the pillar pair first is faster than evaluating four options on their merits.

> [!example] Worked example — the three "check my account" services
> A new CTO asks three questions in one meeting. *"Is anything obviously wasteful or insecure right now?"* → **Trusted Advisor**: it inspects live resources and reports idle load balancers, root accounts without MFA, public S3 buckets. *"Is our payments platform well designed?"* → **Well-Architected Tool**: a structured review of that workload against the pillars, producing documented risks — and a **custom lens** if the company has its own standards to encode. *"How do I know nobody re-opens port 22 next month?"* → neither; that's **AWS Config** with a rule and **SSM Automation** remediation, because it's the only one of the three that is continuous and can act. The exam picks between these constantly, and the discriminator is always **review vs inspect vs continuously enforce**.

> [!failure] Failure mode — treating the framework as paperwork
> A team runs a Well-Architected review, produces a spreadsheet of forty high-risk items, files it, and ships. Six months later the outage postmortem names three items from that spreadsheet. The framework's value is not the review; it's the prioritised remediation and the re-review that shows movement — which is exactly why the WA Tool tracks a workload over time rather than producing a one-off report. The production-grade version pairs it with **Trusted Advisor** for what's true right now and **AWS Config** for what must stay true, so the findings become enforced rather than recorded.

## Traps

> [!warning] Trap — five pillars instead of six
> **Sustainability** is a full pillar, and it's the newest. Course material, blog posts and older practice banks written before it was added say five. If a question asks how many pillars, or lists them, the answer includes **Sustainability**. The same staleness applies to **Trusted Advisor's categories** — **six**, not five, since **Operational Excellence** was added.

> [!warning] Trap — Reliability and Performance Efficiency treated as one thing
> They sound adjacent and are tested apart. **Reliability** is about surviving and recovering from failure — Multi-AZ, health checks, backups, DR strategy. **Performance Efficiency** is about using the *right* resources efficiently — instance selection, caching, the right database for the access pattern. A question asking for "improved performance" is not asking for another Availability Zone, and a question asking for "improved resilience" is not asking for a bigger instance.

> [!warning] Trap — Trusted Advisor assumed to be fully available on any account
> On **Basic or Developer Support** you get **only** the full **Service Limits** category plus a fixed handful of Security and Fault Tolerance checks (MFA on root account, S3 bucket permissions, public EBS/RDS snapshots, unrestricted specific ports, STS global endpoint). Scenarios that require the **full** check set, the **Trusted Advisor API**, or **EventBridge**-driven automation are implicitly requiring a **paid support plan** — and "upgrade the support plan" is sometimes the correct answer rather than a distractor.

> [!warning] Trap — Trusted Advisor asked to do continuous compliance
> Trusted Advisor **recommends**; it does not enforce, and on Basic it doesn't even refresh Security checks automatically. Any scenario wanting **continuous evaluation, configuration history, drift detection or automatic remediation** is describing **AWS Config** (with SSM Automation), not Trusted Advisor. Likewise, a *design* review is the **Well-Architected Tool**, not Trusted Advisor — Trusted Advisor never sees your intent, only your resources.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Written 2026-09-26** from the framework docs and the exam guide; not drilled yet.
- [ ] **Six, not five** — both the pillars (Sustainability) and the Trusted Advisor categories (Operational Excellence). Every older source I've read says five.
- [ ] **Trusted Advisor's free-tier check list** — a specific, memorisable list I'd otherwise guess at.
- [ ] **WA Tool vs Trusted Advisor vs Config** — three "checks your account" services that are offered together.

## 🔗 Docs

- [The pillars of the framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/the-pillars-of-the-framework.html) — the six pillars named and ordered; verified 2026-09-26
- [What is AWS Well-Architected Tool?](https://docs.aws.amazon.com/wellarchitected/latest/userguide/intro.html) — purpose, custom lenses, Trusted Advisor and Service Catalog AppRegistry integration; verified 2026-09-26
- [AWS Trusted Advisor](https://docs.aws.amazon.com/awssupport/latest/user/trusted-advisor.html) · [Trusted Advisor check reference](https://docs.aws.amazon.com/awssupport/latest/user/trusted-advisor-check-reference.html) — the six categories, the Basic/Developer check list, and the 2027 support-plan changes; verified 2026-09-26
- [Disaster Recovery of Workloads on AWS](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-workloads-on-aws.html) — the worked example of a whitepaper as a source, and of one that has aged; see [[14-dr-resilience]]
- [SAA-C03 Exam Guide (PDF)](https://d1.awsstatic.com/training-and-certification/docs-sa-assoc/AWS-Certified-Solutions-Architect-Associate_Exam-Guide.pdf) — domain weightings 30/26/24/20 and the 14 task statements; verified 2026-09-26
