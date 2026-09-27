---
decision: observability
question: How will I know what happened?
spans: [20-monitoring, 25-well-architected]
tags: [decision, domain/resilient]
---

# How will I know what happened?

The notes explain what each watching service records. This routes you to one. Work
top-down — the first question that applies settles it.

## 1. What is being recorded?

The deciding question is **not what you want to see, it is what the service stores.**
Four services, four units of record, and they barely overlap:

- a **number or a log line** your systems emit → **CloudWatch** → §2
- the **API call and its caller** → **CloudTrail** → §3
- the **resource's configuration, versioned over time** → **Config** → §4
- nothing is stored; something must **happen automatically** → **EventBridge** → §5

"Who changed it" and "what did it look like after" are different questions. A stem asks one.

↳ [[20-monitoring#The four services — the discrimination the exam actually tests]]

## 2. CloudWatch — the axis is where the number comes from

- **The hypervisor can see it** (CPU, network, disk I/O) → default metrics, nothing to
  install.
- **It lives inside the guest OS** (memory, disk space used, swap) → the **CloudWatch
  agent**, arriving as **custom metrics**. Detailed monitoring is never the answer here;
  it changes frequency (5 min → 1 min), never coverage.
- **The fact is in a log line** → you cannot alarm on a log group: **metric filter →
  metric → alarm**.
- **You want to ask, not be told** → **Logs Insights**.

Then alarm shape: one metric → **metric alarm**; several alarms combined to cut noise → **composite alarm**, which cannot perform EC2 or Auto Scaling actions.

↳ [[20-monitoring#Getting an alert out of a log line]] · [[20-monitoring#CloudWatch event types]]

## 3. CloudTrail — the axis is how far back, and which plane

- **Last 90 days, one Region, control-plane calls only** → **Event history**. Free, already
  on, nothing to build.
- **Longer retention, multi-Region, or evidence for an auditor** → a **trail** to S3, and
  retention becomes an S3 lifecycle question, not a CloudTrail one.
- **S3 object reads/writes, Lambda invokes, DynamoDB item operations** → still a trail,
  plus an **event selector** — these are **data events** and they are **off by default**.
- **"Unusual call rate or error rate"** measured against your own normal → **Insights**.

↳ [[20-monitoring#Management vs data events (CloudTrail)]]

## 4. Config — the axis is history versus enforcement

- **"Was it ever X, when did it change?"** → configuration items over time.
- **"Make sure it stays X"** → a Config **rule** plus **SSM Automation** remediation —
  Config is the only one of these that can act on what it finds.
- **"Which principal did it?"** → you wanted §3. Config never records the caller.

↳ [[20-monitoring#CloudTrail vs Config, on the same security group change]]

## 5. Reaction — alarm action or EventBridge rule

The axis is **what the trigger is**, not what the target is.

- **A threshold crossed on a metric** → an **alarm action** — the only route to EC2 and
  Auto Scaling actions.
- **An event occurred, or a clock struck** → an **EventBridge rule** on an event pattern
  or a schedule, fanning out to Lambda, SQS, SSM.
- **CloudWatch Events** and **EventBridge** are the same service renamed — if both appear
  as options, the distinction is elsewhere in the wording.

## 6. Something should check the account for me

The axis is **who supplies the judgement.**

- **I answer questions about a workload's design** → **Well-Architected Tool**. Free,
  point-in-time, extensible with lenses.
- **AWS inspects what is deployed** against a fixed check list → **Trusted Advisor**.
  Advisory only, gated by support plan — Basic/Developer gets Service Limits plus a
  short fixed list.
- **It must be evaluated continuously and fixed** → **Config**, back at §4.

Review the design · inspect the resources · continuously enforce. That ordering settles almost every stem offering all three.

↳ [[25-well-architected#WA Tool vs Trusted Advisor vs AWS Config]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **"Enable CloudTrail" to find who read an object.** CloudTrail is already on for
  management events. Object-level access is a **data event**, opt-in via an event
  selector — an answer without that step is incomplete, not merely unoptimised.
- **CloudTrail chosen for state, Config chosen for identity.** The same security-group
  change appears in both, answering opposite questions. "Who" → CloudTrail. "What did it
  look like, and was that compliant" → Config.
- **Detailed monitoring reached for when the metric does not exist.** Memory and free
  disk are not slow, they are absent. The choice is agent-or-nothing; frequency is a
  different decision entirely.
- **The 90 days read as a retention policy.** It is the free console view. A seven-year
  compliance requirement is a trail plus S3 lifecycle — a storage decision wearing a
  CloudTrail costume.
- **A composite alarm wired to a scaling action.** Composite alarms reduce noise and can
  notify; the alarm that actually scales must be a metric alarm on a metric.
- **Trusted Advisor asked to enforce, or to review a design.** It only ever reports on
  deployed resources. Enforcement is Config; design review is the WA Tool.
- **Trusted Advisor assumed fully available.** If the scenario needs the whole check set,
  the API, or EventBridge integration, "upgrade the support plan" is the answer.
