---
decision: compute
question: What should run this workload?
spans: [02-ec2, 17-containers, 19-serverless, 24-other-services, 18-containers-capstone]
tags: [decision, domain/performance]
---

# What should run this workload?

The notes explain each compute service. This routes you to one. Work top-down —
the first question that applies settles it, and §1 and §2 settle most cases.

## 1. Does one unit of work end by itself?

The deciding question is **what is still running when nobody is using this?** A process
that waits for the next request is a *service*; work that is triggered, finishes and
leaves nothing behind is a *job*, and nothing need exist between runs.

| The work | Shape | Go to |
|---|---|---|
| serves requests continuously | **service** | §2 |
| starts, does one thing, exits | **job or function** | §3 |
| several steps, branching, or waiting on something slow | **workflow** | §4 |

## 2. A service — how much of the machine must you still own?

Not "which is most modern" — the axis is **what the workload refuses to give up**.

| The workload needs | Answer |
|---|---|
| kernel tuning, a licensed agent, a GPU or special instance family, an app nobody will containerise | **EC2** |
| a container image run, with no instances for you to patch or bin-pack | **ECS + Fargate** |
| existing Kubernetes manifests, Helm charts, a team that already speaks kubectl | **EKS** |
| a plain web stack — instances, ALB, ASG — provisioned for you and still visible in your account | **Elastic Beanstalk** |
| steady, heavy, tightly packable load on instances you pay for anyway | ECS, **EC2 launch type** |

"ECS or Fargate" is not a fork: ECS is the orchestrator, and the launch type answers
a second question — *who owns the servers underneath*. EKS can use Fargate too.

↳ [[17-containers#ECS vs EKS]] · [[17-containers#EC2 launch type vs Fargate]] · [[24-other-services#Elastic Beanstalk — PaaS with the lid off]] · [[02-ec2#What an instance is actually made of]]

## 3. A job — can one unit finish inside 15 minutes?

- **Yes, and something emits an event** → **Lambda**. Then check *how* it is triggered,
  because that decides who retries on failure.
- **No** → **AWS Batch** (job queue, any Docker image, no time limit), or a one-off
  **Fargate task**. "Nightly job that takes four hours" is Batch.
- **Yes, but a steady firehose** → still Lambda; the question moves to concurrency —
  reserved caps it, provisioned pre-warms it.

↳ [[24-other-services#Batch vs Lambda]] · [[19-serverless#The three Lambda invocation models]] · [[19-serverless#Reserved vs provisioned concurrency]]

## 4. A workflow — does any step wait on something that is not code?

- **Yes — a human approving, or a job running for hours** → **Step Functions Standard**.
  Only it has `.waitForTaskToken`, and it can run for a year.
- **No, and the volume is enormous with short runs** → **Express**: five-minute cap,
  at-least-once.
- **Neither — three functions in a row** → you may not need a workflow at all; the
  reason to reach for one is seeing *which step stopped*.

↳ [[24-other-services#Step Functions — Standard vs Express]]

## 5. Can a unit be killed mid-flight and simply re-run?

If yes, the capacity answer is **Spot** — Fargate Spot for tolerant tasks, Batch on
Spot for restartable batch. If re-running loses in-flight state or drops user
requests, it is not Spot.

## 6. What sits in front of it?

The axis is **what it costs at zero traffic**, not features.

- **Lambda behind an HTTP API** → **API Gateway**. Nothing runs idle, nothing bills idle.
- **A fleet of containers or instances to spread traffic across** → **ALB**: billed
  hourly forever, cheaper once volume amortises it.
- **GraphQL, or real-time subscriptions** → **AppSync**.

↳ [[19-serverless#API Gateway vs ALB as a front door]] · [[24-other-services#AWS AppSync — managed GraphQL]]

## 7. Is it already running somewhere else?

| Situation | Answer |
|---|---|
| Lift and shift whole servers as they are | **Application Migration Service (MGN)** |
| The database has to come too | **DMS**, plus **SCT** first if the engines differ |
| It must keep running on your own hardware | **ECS Anywhere / EKS Anywhere** |

↳ [[24-other-services#AWS DMS — the migration answer, and the biggest gap here]] · [[24-other-services#The long tail — recognise and eliminate]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **Choosing serverless on "no servers" instead of on idle cost.** A Fargate service
  with one task has no servers you patch and still bills every second — and an ALB in
  front of either answer quietly reintroduces an hourly charge.
- **Treating Lambda's 15 minutes as a performance problem.** More memory buys CPU and
  can halve a duration — the instinct works right up to the ceiling, then stops working
  entirely. Past 15 minutes you need a different service, not a bigger function.
- **Reaching for Batch because a job sounds big.** It has queue and provisioning latency
  Lambda does not; short spiky event-driven work on Batch is the same mistake inverted.
- **Carrying one compute service's IAM shape onto another.** ECS splits execution role
  from task role, Lambda has one role doing both, EC2 takes an *instance profile* — the
  wrong model means hunting a split that was never there.
- **Giving a VPC-attached Lambda a public subnet.** Correct reflex for EC2, useless
  here — a Lambda ENI never gets a public IP. Private subnet plus NAT, or endpoints.
- **Rejecting Beanstalk as "extra cost" or "a black box".** It charges nothing itself
  and leaves the instances, ASG and load balancer in your account. A plain web app on a
  container service is often the harder path chosen for the wrong reason.
