---
topic: 24-other-services
domain: performance
status: reviewed
services: [DMS, StepFunctions, AppSync, Batch, ElasticBeanstalk, TransferFamily, DirectoryService, Cognito, CloudFormation, ServiceCatalog]
related: [19-serverless, 15-decoupling, 07-rds-aurora, 01-iam-advanced, 12-storage-extras]
tags: [topic, domain/performance]
---

# 24 – Other Services

The catch-all. Seven services that are individually too small for their own note and collectively worth about **120 bank questions** — more than Route 53.

> [!info] Exam TL;DR
> - **DMS** migrates data and can **keep replicating (CDC)** so downtime is minimal; it runs on a **replication instance**. **Different engines ⇒ convert the schema first with AWS SCT / DMS Schema Conversion.** Oracle → Aurora PostgreSQL = **SCT + DMS**.
> - **DMS targets are not just databases:** **Redshift**, **S3**, **DynamoDB**, **OpenSearch**, **Kinesis Data Streams**, Kafka, Neptune, DocumentDB — and **S3 can be a source**. "Continuously replicate RDS into a warehouse" = **DMS → Redshift**, not Glue or EMR.
> - **DMS Serverless** auto-provisions and scales capacity (a **replication configuration**, no instance to size) — the answer for **spiky volume + least operational overhead**.
> - **Too big for the bandwidth?** The **retired but still-examined** answer: **SCT + a local DMS Agent** extract onto a **Snowball Edge**, AWS unloads to **S3**, a **remote DMS task** loads the target — DMS itself does *not* extract. Current answer is **DataSync**.
> - **Step Functions Standard:** exactly-once, up to **1 year**, priced per **state transition**, supports **.sync** and **.waitForTaskToken** (human approval). **Express:** at-least-once, **5 minutes**, 100,000/sec, priced by count+duration, **Request Response only**.
> - **AppSync = managed GraphQL** with real-time **WebSocket subscriptions**; API Gateway = REST/HTTP/WebSocket. Amplify is built on AppSync.
> - **AWS Batch** runs **containerised** jobs on ECS/EKS across EC2/Fargate/**Spot**, with **no time limit** — the answer when Lambda's **15 minutes** isn't enough.
> - **Elastic Beanstalk** provisions EC2 + ELB + ASG + health monitoring from uploaded code. **No charge for Beanstalk itself — only the underlying resources.** You still control the resources.
> - **Transfer Family** = managed **SFTP / FTPS / FTP / AS2** into **S3 or EFS**, when partners' clients can't change. **AS2 = B2B/EDI.** Not the same as DataSync.
> - **Directory Service:** **Managed Microsoft AD** = real AD, trusts, MFA, schema extensions, **works with RDS SQL Server**. **AD Connector** = proxy to on-premises AD, stores nothing. **Simple AD** = Samba 4, basic, **no MFA/trusts/schema extensions**. Neither AD Connector nor Simple AD supports RDS SQL Server.
> - For a **SaaS app's own users**, the answer is **Cognito**, not Directory Service.
> - **QLDB** = immutable verifiable ledger. **AppFlow** = SaaS↔AWS data transfer. **Wavelength** = 5G edge. **License Manager** = BYOL tracking.

> [!warning] Build tier — **conceptual-only**
> Nothing here is free-tier friendly (DMS replication instances, Beanstalk environments and Directory Service directories all bill hourly) and none of it is Terraform-interesting. Read, drill, move on.

## What problem does this solve?

This note exists because of a gap audit, not because the services belong together.

I checked all **130 in-scope services** in the SAA-C03 exam guide against this vault and then counted how many of the 1,168 practice-bank questions touch each one. Seven came back with real exam weight and little or no coverage here:

| Service | Bank questions | Was in the vault |
|---|---|---|
| **DMS** | ~33 | two passing mentions |
| **Step Functions** | 21 | thin |
| **Directory Service** | 17 | thin |
| **AppSync** | 16 | thin |
| **AWS Batch** | 13 | nothing |
| **Elastic Beanstalk** | 12 | one mention |
| **Transfer Family** | 7 | nothing |

None is conceptually deep. All of them are *recognition plus one distinguishing fact* — which is exactly the kind of mark that's cheap to win and annoying to lose.

> In one line: seven small services with real exam weight and no home elsewhere in the vault.

## How it actually works

### AWS DMS — the migration answer, and the biggest gap here

**AWS Database Migration Service** migrates relational databases, data warehouses, NoSQL databases and other data stores — into AWS, or between cloud and on-premises in either direction.

Mechanically it's simpler than it sounds: DMS is *"a server in the AWS Cloud that runs replication software."* You create a **replication instance**, define a **source endpoint** and a **target endpoint**, and schedule a **task** that moves the data. DMS creates the target tables and primary keys if they don't already exist.

Two facts carry most of the exam weight.

**One-time migration versus continuous replication.** A task can do a one-off load, or it can **replicate ongoing changes to keep source and target in sync** — change data capture. That's what makes "migrate with minimal downtime" possible: you do the bulk load while the source stays live, let CDC catch up, then cut over.

**Homogeneous versus heterogeneous.** Same engine on both ends (Oracle → Oracle, MySQL → Aurora MySQL) is homogeneous and DMS alone handles it. **Different engines** (Oracle → Aurora PostgreSQL, SQL Server → MySQL) is heterogeneous, and the *schema* has to be converted first — tables, indexes, views, triggers, stored procedures. That's **AWS Schema Conversion Tool (AWS SCT)**, which you download, or **DMS Schema Conversion**, which does it inside the service.

The exam question is almost always some form of: *"migrate a 5 TB on-premises Oracle database to Aurora PostgreSQL with minimal downtime."* Answer: **SCT to convert the schema, then DMS with ongoing replication to move the data and keep it current until cutover.**

Also worth a line each: **DMS Fleet Advisor** inventories your on-premises database estate to help plan a migration, data at rest is encrypted with **KMS** and in flight with **SSL**, and DMS provides **automatic failover** to a backup replication server.

**It is not only database-to-database.** This is the part most people carry wrongly: DMS reads
from and writes to things that are not relational databases at all, which is why it turns up as
the answer to questions that look like analytics or streaming problems.

| Direction | Includes |
|---|---|
| **Targets** | RDS · Aurora (incl. **Babelfish**) · **Redshift** and **Redshift Serverless** · **S3** · **DynamoDB** · **OpenSearch Service** · ElastiCache (Redis OSS) · **Kinesis Data Streams** · DocumentDB · Neptune · Apache Kafka |
| **Sources** | the commercial and open-source engines, plus **S3** |

So "continuously replicate several RDS databases into a petabyte-scale warehouse" is **DMS →
Redshift**, not Glue and not EMR. "Stream existing S3 files and ongoing updates into Kinesis Data
Streams" is **DMS with S3 as the source**, not a Lambda triggered by S3 events. "Move an embedded
NoSQL database to a managed one" is **DMS → DynamoDB**.

**DMS Serverless.** The replication *instance* above is the Standard model, where you size and
manage the compute. **DMS Serverless** instead does *"automatic provisioning, scaling, built-in
high availability, and a pay-for-use billing model"*, and *"eliminates replication instance
management tasks like capacity estimation, provisioning, cost optimization, and managing
replication engine versions and patching."* You create a **replication configuration** rather than
an instance; DMS inspects the source metadata, computes the capacity it needs, and scales as the
workload moves. Trigger words: load that **varies or spikes**, *"dynamically allocate capacity"*,
**least operational overhead**.

> [!warning] Currency — the DMS + Snowball Edge path is retired
> The exam still asks it, so recognise it; do not carry it as current practice.
> **How it worked:** locally you ran **AWS SCT** plus a **DMS Agent** (an on-premises build
> of DMS) to extract the data onto an **AWS Snowball Edge** device; you shipped the device
> back; AWS unloaded it into an **Amazon S3** staging bucket; then a **remote DMS task**
> migrated from S3 into the target. The testable half is the division of labour — cloud DMS
> never reached into your data centre, so an option saying *DMS* performed the extraction has
> the two halves reversed.
> **Why it is retired:** AWS has **removed the large-data-store/Snowball Edge chapter from the
> DMS user guide** (`CHAP_LargeDBs.md` now 404s while sibling chapters resolve), Snowball Edge
> has been **closed to new customers since 2025-11-07**, and support for Snowball devices
> **ends in all commercial Regions on 2026-12-31**. Today the same problem is answered with
> **DataSync** over the network, or **AWS Data Transfer Terminal** for physical transfer.
> See [[12-storage-extras]]. (Verified 2026-09-30; mechanism from an archived 2022 copy of the
> removed chapter, since no live AWS page documents it.)

> In one line: DMS moves the data and keeps it in sync with CDC, SCT converts the schema when the
> engines differ, and the target can be a warehouse, a stream or a NoSQL store — not just a database.

### Step Functions — orchestration, and one table that gets tested

**AWS Step Functions** builds **state machines** — called *workflows* — out of event-driven steps called *states*. A running instance is an *execution*. The console visualises and debugs the whole thing, which is the practical reason teams pick it over chaining Lambdas by hand.

The state types worth recognising: **Task** (do a unit of work), **Choice** (branch on input), **Parallel** (run branches concurrently), **Map** (run steps over every item in a dataset), plus **Retry** and **Catch** for error handling.

The exam-testable part is the workflow type split:

| | **Standard** | **Express** |
|---|---|---|
| Execution semantics | **exactly-once** | **at-least-once** |
| Max duration | **1 year** | **5 minutes** |
| Execution rate | 2,000/sec | **100,000/sec** |
| Priced by | **state transition** | number **and duration** of executions |
| Execution history | in Step Functions | sent to **CloudWatch Logs** |
| Integration patterns | Request Response, **Run a Job (.sync)**, **Wait for Callback** | **Request Response only** |
| Built for | long-running, auditable workflows | high-event-rate streaming, IoT ingestion |

The three **service integration patterns** matter too: **Request Response** (call and continue), **Run a Job (`.sync`)** (call and wait for the job to finish), and **Wait for Callback (`.waitForTaskToken`)** (pause until something calls back with a token). That last one is how **human-in-the-loop approval** is built — the workflow waits, possibly for days, until a person approves. Express workflows can't do it.

> In one line: Standard is exactly-once and runs up to a year; Express is at-least-once, capped at five minutes, and built for volume.

### AWS AppSync — managed GraphQL

**AWS AppSync** provides **serverless GraphQL and Pub/Sub APIs**. One endpoint fronts **multiple data sources** — DynamoDB, Lambda, RDS, OpenSearch, HTTP — so a client fetches exactly the fields it wants in one round trip instead of calling four REST endpoints.

The features that show up in questions: **real-time updates via serverless WebSockets** (GraphQL subscriptions), **server-side caching** for low latency, and authorization via **API keys, IAM, Amazon Cognito, OpenID Connect, or Lambda** authorizers.

The discriminator against **API Gateway** is simply the API style: REST/HTTP/WebSocket → API Gateway; **GraphQL → AppSync**. If a scenario says "mobile app needs real-time data and offline sync", that's AppSync (usually via **Amplify**, which is built on it).

> In one line: GraphQL means AppSync, and it brings real-time subscriptions over WebSockets for free.

### AWS Batch — containerised batch jobs at any scale

**AWS Batch** runs batch computing workloads: you submit **jobs** to **job queues**, and Batch provisions **compute environments** to run them, scaling capacity to match the queue. Jobs run as **containers** on **Amazon ECS and Amazon EKS**, across **EC2 instances, Fargate, and Spot or On-Demand** capacity.

The exam discriminator is against **Lambda**:

- **Lambda**: event-driven, 15-minute ceiling, limited runtimes and package size, no capacity to manage.
- **Batch**: **no time limit**, any Docker image, any runtime, purpose-built for long-running compute-heavy jobs — genomics, rendering, simulation, financial modelling.

"Nightly job that takes four hours" is Batch, not Lambda. Cost-wise, Batch on **Spot** is the standard answer for tolerant, restartable batch work.

> In one line: Batch is for containerised jobs too long or too heavy for Lambda, and Spot is its natural home.

### Elastic Beanstalk — PaaS with the lid off

**Elastic Beanstalk** deploys web applications: you upload the code, and Beanstalk provisions the **EC2 instances, load balancing, health monitoring and auto scaling** for you. Supported platforms are **Go, Java, .NET, Node.js, PHP, Python and Ruby**, plus **Docker**.

Two facts do the work on the exam:

**There is no charge for Elastic Beanstalk itself — you pay only for the underlying AWS resources.** That makes it the answer to "deploy quickly with the least effort and no extra cost" questions.

**You keep full control of the resources it creates.** Unlike a black-box PaaS, the EC2 instances, ASG and load balancer are in your account and you can inspect and tune them. That's the line between Beanstalk and "fully managed" — it's *provisioning* automation, not abstraction.

Environments come in two shapes: a **web server environment** (serves requests) and a **worker environment** (processes from an SQS queue) — the same split you know from [[15-decoupling]].

> In one line: Beanstalk provisions and manages a standard web stack for you, costs nothing extra, and leaves the resources visible in your account.

### AWS Transfer Family — SFTP as a managed service

**AWS Transfer Family** provides fully managed file transfer **over SFTP, FTPS, FTP and AS2**, plus browser-based transfers, landing files directly in **Amazon S3 or Amazon EFS**.

The scenario is always the same: a company has partners who upload files over SFTP and **cannot change their clients**. Transfer Family gives you a protocol endpoint without running any server infrastructure — you keep the existing client configs, authentication and firewall rules, and the data lands in S3 where the rest of AWS can reach it. It's backed by an **auto-scaling redundant fleet across up to three Availability Zones**.

**AS2** is the one to recognise separately — it's the B2B/EDI protocol, so supply-chain, payments and ERP integration scenarios point at it.

Don't confuse it with **DataSync** ([[12-storage-extras]]): DataSync is for bulk one-off or scheduled *dataset* transfer between storage systems; Transfer Family is a *standing protocol endpoint* for external parties.

> In one line: Transfer Family is managed SFTP/FTPS/FTP/AS2 into S3 or EFS, for partners whose clients can't change.

### AWS Directory Service — three options, one real discriminator

**AWS Directory Service** provides Microsoft Active Directory for AWS. Three options, and the exam tests picking between them:

**AWS Managed Microsoft AD** is *actual Microsoft Active Directory* running in AWS, managed by AWS. It supports **trusts** with on-premises AD, **schema extensions**, **MFA**, **LDAPS**, Group Policy, and — the detail that decides questions — **Amazon RDS for SQL Server**. Standard Edition targets ~30,000 directory objects; Enterprise Edition ~500,000.

**AD Connector** is a **proxy**. It stores nothing: sign-in requests are **forwarded to your existing on-premises domain controllers** for authentication. No directory in the cloud, no synchronisation, no federation infrastructure. It exists so on-premises users can sign in to AWS applications with their existing credentials. **Not compatible with RDS SQL Server.**

**Simple AD** is a **Samba 4**-powered, Active-Directory-*compatible* standalone directory. Basic features only — user accounts, group membership, domain join, Kerberos SSO, group policies. It explicitly does **not** support **MFA, trust relationships, schema extensions, LDAPS, or PowerShell AD cmdlets**, and is **not compatible with RDS SQL Server**. It's the low-cost option for basic needs.

And the fourth answer that isn't Directory Service at all: for a **SaaS application's own end users**, the answer is **Amazon Cognito**, not a directory.

> In one line: Managed Microsoft AD is real AD (and the only one that does RDS SQL Server), AD Connector proxies to on-prem, Simple AD is a cheap Samba-based imitation.

### Amazon Cognito — two pools that do different jobs

The previous section ends by saying a SaaS app's own users are a Cognito question, not a
Directory Service one. This is that answer. Cognito has **two independent components**, and
telling them apart *is* the exam question:

- **User pool** — a **user directory and authentication server**. Users sign up and sign in;
  it issues **JWTs** (ID and access tokens). It can federate to Google, Apple, Facebook, or
  to SAML/OIDC corporate IdPs, and supports **MFA**. This is the one that answers *"who are
  you"*.
- **Identity pool** — issues **temporary AWS credentials via STS** so the app can call AWS
  services directly. It takes a trusted token — often from a user pool, but a SAML or social
  token works too — and exchanges it for a role session. It can also issue **guest
  (unauthenticated) credentials**. This is the one that answers *"what may you touch in my
  account"*.

**ALB and CloudFront can authenticate for you.** An **Application Load Balancer** has
built-in **Cognito user pool** authentication — the listener rule authenticates the user before
the request ever reaches your instances, which is how a scenario "decouples user
authentication from the application". That integration is with a **user pool**; an identity
pool has no part in it.

They **work independently or together**. The combined flow is the one scenarios describe:
sign in at the **user pool** → exchange the token at the **identity pool** → get temporary
credentials → call **S3 or DynamoDB directly from the mobile app**.

> [!warning] Trap — user pool offered where an identity pool is needed
> The tell is what the app does *after* signing in. If it only needs to know who the user is,
> or to put a token in front of an API, that is a **user pool**. The moment the scenario says
> the app calls **an AWS service directly** — uploads to S3, reads DynamoDB from the phone —
> it needs **AWS credentials**, and only an **identity pool** mints those. "Guest/unauthenticated
> access to a bucket" is identity pool by definition. And neither is **Directory Service**:
> that is workforce identity ([[24-other-services]] above), Cognito is customer identity.

> In one line: user pool authenticates people and hands out JWTs; identity pool converts a
> token into temporary AWS credentials.

### AWS CloudFormation — the standardisation answer

AWS's own IaC. A **template** describes the resources; a **stack** is what that template
creates, managed **as a single unit** — delete the stack and it deletes the resources. There
is **no charge for CloudFormation itself** with `AWS::*` resources; you pay for what it
builds.

Four features carry the exam weight:

| Feature | What it answers |
|---|---|
| **StackSets** | deploy one template across **many accounts and Regions in a single operation** — the multi-account standardisation answer, driven from an admin account or via Organizations |
| **Change sets** | **preview** what an update would add, modify or delete before applying it |
| **Drift detection** | has someone changed these resources **outside** CloudFormation? |
| **`DeletionPolicy`** | what happens to a resource when the stack is deleted — default is **Delete**; `Retain` keeps it, `Snapshot` takes one first (RDS, EBS and friends) |

**AWS Service Catalog** sits above it: administrators publish **approved products** as
portfolios, and end users launch only those, within the constraints set for them. "Let teams
self-serve, but only pre-approved configurations" is Service Catalog, not raw CloudFormation.

> In one line: CloudFormation manages a stack as one unit, StackSets spans accounts and
> Regions, drift detection catches out-of-band edits, and Service Catalog is the approved-
> products layer on top.

### The long tail — recognise and eliminate

These are in scope but carry 0–4 bank questions each. One line is the correct investment:

| Service | One line |
|---|---|
| **Amazon QLDB** | immutable, cryptographically verifiable **ledger** database — an append-only journal with history you can prove |
| **Amazon AppFlow** | no-code data transfer between **SaaS apps** (Salesforce, Slack, Zendesk) and AWS |
| **AWS Application Migration Service (MGN)** | lift-and-shift **server** migration by block-level replication (the DR cousin — see [[14-dr-resilience]]) |
| **AWS Application Discovery Service** | inventories on-premises servers to plan a migration |
| **AWS Migration Hub** | single dashboard tracking migration progress across tools |
| **AWS License Manager** | tracks and enforces **BYOL** software licences |
| **AWS Wavelength** | compute embedded in **5G** networks for ultra-low latency to mobile devices |
| **AWS Proton** | templated infrastructure delivery for platform teams |
| **Amazon Pinpoint** | targeted customer **marketing/transactional messaging** at scale |
| **Amazon Managed Grafana / Managed Service for Prometheus** | managed observability dashboards and metrics ([[20-monitoring]]) |
| **Amazon Elastic Transcoder / Kinesis Video Streams** | media transcoding / ingesting video streams |
| **ECS Anywhere / EKS Anywhere** | run ECS or EKS on **your own** on-premises hardware |
| **AWS Cost and Usage Report** | the most granular billing data export ([[13-cost-optimization]]) |
| **AWS Serverless Application Repository / Device Farm** | share serverless apps / test on real mobile devices |

> In one line: for the long tail, knowing the one-line purpose is enough to eliminate them as distractors.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| Migration | `aws_dms_replication_instance`, `aws_dms_endpoint`, `aws_dms_replication_task` | Instance bills hourly. |
| Workflow | `aws_sfn_state_machine` | `type = "STANDARD"` or `"EXPRESS"`. |
| GraphQL API | `aws_appsync_graphql_api`, `aws_appsync_datasource`, `aws_appsync_resolver` | |
| Batch | `aws_batch_compute_environment`, `aws_batch_job_queue`, `aws_batch_job_definition` | The three-part shape is the mental model. |
| PaaS app | `aws_elastic_beanstalk_application`, `aws_elastic_beanstalk_environment` | |
| Managed SFTP | `aws_transfer_server`, `aws_transfer_user` | |
| Directory | `aws_directory_service_directory` | `type` selects MicrosoftAD / ADConnector / SimpleAD. |

## Key facts, limits & pricing

- **AWS DMS** migrates relational databases, data warehouses, NoSQL databases and other data stores, into AWS or between cloud and on-premises. It is *"a server in the AWS Cloud that runs replication software"* — the **replication instance**. It **creates target tables and primary keys if they don't exist**, supports **one-time migration or ongoing replication to keep source and target in sync**, provides **automatic failover to a backup replication server**, and encrypts data at rest with **KMS** and in flight with **SSL**. It supports **fully heterogeneous** migrations between supported engines.
- **AWS SCT / DMS Schema Conversion** converts source schemas and code objects (tables, indexes, views, triggers) to the target engine. **DMS Fleet Advisor** inventories on-premises database and analytics servers to identify migration candidates.
- **Step Functions Standard workflows:** exactly-once, up to **one year**, **2,000 executions/sec**, **4,000 state transitions/sec**, priced **by state transition**, execution history retained in Step Functions.
- **Step Functions Express workflows:** at-least-once, up to **five minutes**, **100,000 executions/sec**, near-unlimited state transitions, priced by **number and duration** of executions, history sent to **CloudWatch**.
- **Step Functions integration patterns:** Request Response (default), **Run a Job (`.sync`)**, **Wait for Callback (`.waitForTaskToken`)**. **Express supports Request Response only.** States include Task, Choice, Parallel, Map, with Retry/Catch error handling.
- **AWS AppSync** delivers serverless **GraphQL and Pub/Sub** APIs over one endpoint spanning multiple data sources, with **serverless WebSocket subscriptions**, server-side caching, and authorization via **API keys, IAM, Cognito, OIDC or Lambda**. Priced per million requests and real-time updates; **auth/authn failures are not charged**.
- **AWS Batch** runs batch workloads on **Amazon ECS and Amazon EKS**, scaling on **EC2 instances, Fargate and Spot/On-Demand**. Fully managed — no batch software to install. It also queues **SageMaker Training** jobs.
- **Elastic Beanstalk** provisions EC2 instances (or EKS clusters), configures load balancing, sets up health monitoring and scales the environment. Platforms: **Go, Java, .NET, Node.js, PHP, Python, Ruby, and Docker**. **"There is no additional charge for Elastic Beanstalk. You pay only for the underlying AWS resources."** Web server and worker environment types.
- **AWS Transfer Family** supports **SFTP (v3), FTPS, FTP, AS2** and browser-based transfers into **S3 or EFS**, fully managed with **no server infrastructure**, across **up to 3 Availability Zones** on an auto-scaling redundant fleet. **Managed File Transfer Workflows (MFTW)** automate post-upload processing (copy, tag, scan, compress, encrypt). FTP/FTPS data channel uses ports **8192–8200**.
- **AWS Managed Microsoft AD** is actual Microsoft AD; supports trusts with on-premises AD, **schema extensions, password policies, LDAPS, MFA**; **Standard Edition ~30,000 objects**, **Enterprise Edition ~500,000** (approximate); works with **RDS for SQL Server**; HIPAA/PCI-eligible when compliance is enabled.
- **AD Connector** is a **proxy** that forwards sign-in requests to on-premises domain controllers — **no directory sync, no federation infrastructure**; supports seamless EC2 domain join and RADIUS-based MFA; **not compatible with RDS SQL Server**.
- **Simple AD** is **Samba 4**-based and AD-*compatible*. It does **not** support **MFA, trust relationships, DNS dynamic update, schema extensions, LDAPS, PowerShell AD cmdlets or FSMO role transfer**, and is **not compatible with RDS SQL Server**.

- **DMS is not database-to-database only.** Targets include **Redshift / Redshift Serverless**, **S3**, **DynamoDB**, **OpenSearch**, **Kinesis Data Streams**, DocumentDB, Neptune, Apache Kafka and **Babelfish** for Aurora PostgreSQL; **S3 can also be a source**. DMS → Redshift beats Glue/EMR for *continuous replication into a warehouse*.
- **DMS Serverless** vs **DMS Standard**: Serverless auto-provisions and auto-scales capacity with built-in HA and pay-for-use, and removes capacity estimation, provisioning and engine patching. You define a **replication configuration**, not a replication instance. Trigger: spiky/variable volume + least operational overhead.
- **DMS with Snowball Edge — RETIRED, still examinable:** **AWS SCT + a local DMS Agent** extract to the Edge device → ship back → AWS loads into an **S3** staging bucket → a **remote DMS task** loads S3 into the target. Cloud DMS does not do the extraction. AWS has removed this chapter from the DMS user guide; Snowball support ends **2026-12-31**. Modern answer: **DataSync** or **AWS Data Transfer Terminal**.
*Verified against AWS docs 2026-09-30.*

## Comparisons

### Step Functions — Standard vs Express

|   | **Standard** | **Express** |
|---|---|---|
| Execution semantics | **exactly-once** | **at-least-once** |
| Maximum duration | **1 year** | **5 minutes** |
| Execution rate | 2,000/sec | **100,000/sec** |
| Pricing basis | **per state transition** | per execution **count + duration** |
| History | in Step Functions | **CloudWatch Logs** |
| `.sync` / `.waitForTaskToken` | **✓** | **✗ (Request Response only)** |
| Use case | long, auditable, human-approval | high-volume streaming / IoT |

### Directory Service options

|   | **Managed Microsoft AD** | **AD Connector** | **Simple AD** |
|---|---|---|---|
| What it is | **real Microsoft AD** in AWS | **proxy** to on-premises AD | **Samba 4**, AD-compatible |
| Stores users in AWS | **✓** | **✗ — forwards to on-prem** | ✓ |
| Trusts with on-prem AD | **✓** | n/a | **✗** |
| MFA | ✓ | ✓ (via RADIUS) | **✗** |
| Schema extensions / LDAPS | **✓** | n/a | **✗** |
| **RDS for SQL Server** | **✓** | **✗** | **✗** |
| Pick when | you need actual AD features in AWS | on-prem users signing in to AWS apps | cheap, basic directory |

### Batch vs Lambda

|   | **AWS Batch** | **AWS Lambda** |
|---|---|---|
| Time limit | **none** | **15 minutes** |
| Packaging | **any Docker image** | zip or container, limited runtimes |
| Runs on | ECS/EKS over EC2, Fargate, **Spot** | fully abstracted |
| Scaling trigger | **job queue depth** | per-event invocation |
| Built for | long compute-heavy batch | short event-driven functions |

### Transfer Family vs DataSync

|   | **Transfer Family** | **DataSync** |
|---|---|---|
| Shape | **standing protocol endpoint** | **transfer job / agent** |
| Protocols | **SFTP, FTPS, FTP, AS2** | NFS, SMB, HDFS, object stores |
| Who initiates | **external partners with their own clients** | you, on a schedule or one-off |
| Typical ask | "partners upload over SFTP, can't change clients" | "move 50 TB from on-prem NAS to S3" |

## Worked examples

> [!example] Worked example — the Oracle migration question
> *"A company runs a 5 TB Oracle database on-premises and wants to move to Amazon Aurora PostgreSQL. The business will tolerate only a few minutes of downtime."*
> Two problems, two tools. The engines differ, so the **schema** won't transfer as-is — stored procedures, triggers, data types all need translating. That's **AWS SCT** (or DMS Schema Conversion). Then the **data**: create a **DMS replication instance**, point a task at the Oracle source and the Aurora target, and run a **full load plus ongoing replication (CDC)**. The bulk copy happens while Oracle stays live and serving; CDC streams the changes made during that copy; when the lag reaches near zero you stop the application, let the last changes drain, and repoint it at Aurora. Downtime is the cutover, not the copy — which is the whole point, and the reason "export a dump and restore it" is the wrong answer at 5 TB.

> [!example] Worked example — picking the workflow type
> Two orchestration scenarios, deliberately close. **(a)** *"An insurance claim workflow calls three services, then waits for a human adjuster to approve before paying out. Approval can take days, and every step must be auditable."* → **Standard**: it runs up to a year, gives exactly-once execution, keeps the execution history, and — decisively — supports **`.waitForTaskToken`**, which is how you pause for a human. **(b)** *"Process 50,000 IoT telemetry events per second, each through a short three-step transformation."* → **Express**: 100,000/sec, five-minute cap is ample, priced by duration rather than per transition (which at that volume is the difference between viable and absurd). The at-least-once semantics are acceptable because the transformation is idempotent. Pick on **duration and volume**, not on which sounds more robust.

> [!failure] Failure mode — the SFTP server nobody wanted to run
> A company keeps an EC2 instance running `sshd` so partners can drop files by SFTP. It works, until it doesn't: the instance is a single point of failure in one AZ, patching it is someone's unglamorous job, the host keys are backed up nowhere, disk fills silently, and files sit on an EBS volume that no analytics tool can read without a copy step. **Transfer Family** removes every one of those: a managed endpoint across up to three AZs on an auto-scaling fleet, files landing **directly in S3** where Athena, Glue and lifecycle policies already work, and partners noticing nothing because their clients, credentials and firewall rules are unchanged. The tell that you're in this failure mode: **the thing keeping your file transfer alive is a person remembering to patch a box.**

## Traps

> [!warning] Trap — DMS offered as the tool that extracts to the Snowball Edge device
> On the **retired** Snowball path above — which the exam still asks — the shape of the answer is
> **SCT extracts to the device, DMS finishes in the cloud**. Options reverse it — "use **DMS** to extract and load
> the data to a Snowball Edge device" — and it is wrong because the cloud service has no presence
> in your data centre; the local extraction is done by **AWS SCT** together with a **DMS Agent**
> installed on-premises. Also wrong: **Direct Connect** "so DMS can migrate directly", which
> solves bandwidth with months of lead time and cost when the stem said *within the next few
> weeks*; and **enabling compression** then migrating directly, which does not change the order of
> magnitude.

> [!warning] Trap — Glue, EMR or Kinesis offered for continuous database replication
> A stem wanting several RDS databases **continuously consolidated into Redshift**, with least
> development effort and no infrastructure to manage, is **DMS**. **Glue** is ETL — batch jobs and
> a catalogue, not change data capture off a live database. **EMR** is a managed Hadoop/Spark
> cluster, which is infrastructure the stem explicitly did not want. **Kinesis Data Streams** is a
> stream you would still have to write producers and consumers for. DMS does CDC natively and
> takes **Redshift as a target**, which is the whole reason it wins.

> [!warning] Trap — DMS alone for a heterogeneous migration
> DMS moves **data**. It does not translate a **schema** between different engines. Any Oracle→PostgreSQL or SQL Server→MySQL scenario needs **AWS SCT / DMS Schema Conversion** first, then DMS. An option offering "use DMS to migrate the database" with no schema-conversion step is incomplete for heterogeneous migrations — and is the correct answer only when the source and target run the **same** engine.

> [!warning] Trap — Standard vs Express workflows
> Decide on **duration and volume**, not sophistication. **Express caps at five minutes** and is **at-least-once** — so anything long-running, anything needing exactly-once, and anything waiting on a **human approval** (`.waitForTaskToken`, which Express doesn't support) must be **Standard**. Conversely, at tens of thousands of events per second, Standard's per-state-transition pricing is the wrong cost model. "Human approval" in a question is effectively a Standard flag.

> [!warning] Trap — AD Connector or Simple AD where RDS for SQL Server is involved
> **Only AWS Managed Microsoft AD works with Amazon RDS for SQL Server.** AD Connector and Simple AD are both explicitly incompatible. Directory questions frequently bury an RDS SQL Server requirement in the scenario precisely because it collapses three options to one. Same logic for **trusts, schema extensions, LDAPS and MFA** — Simple AD supports none of them.

> [!warning] Trap — Lambda for a job that outgrows 15 minutes
> Lambda's **15-minute** maximum is a hard ceiling, and scenarios describing genomics processing, video rendering, simulations or multi-hour ETL are built around it. The answer is **AWS Batch** (containerised, no time limit, Spot-friendly) or ECS/Fargate tasks. Watch for the inverse too: a short, event-driven, spiky workload put on Batch is over-engineering — Batch has queue and provisioning latency that Lambda doesn't.

> [!warning] Trap — Transfer Family confused with DataSync
> Both move files into AWS and both appear together as options. **Transfer Family is a standing endpoint speaking SFTP/FTPS/FTP/AS2, for external parties using their own clients.** **DataSync is a transfer job you run** to move a dataset between storage systems. "Partners upload to us and can't change their software" → Transfer Family. "Migrate 50 TB from an on-premises NAS" → DataSync. If the question names a **protocol**, it's Transfer Family.

> [!warning] Trap — assuming Elastic Beanstalk costs extra or hides the resources
> **Beanstalk itself is free — you pay only for the EC2, ELB and other resources it creates**, so "additional service cost" is never a reason to reject it. And it doesn't abstract the infrastructure away: the instances, ASG and load balancer live in your account and remain fully inspectable and tunable. Beanstalk is the answer for "deploy this app quickly with minimal setup **while keeping control of the infrastructure**" — which is exactly what distinguishes it from a fully managed container service.

> [!warning] Trap — reaching for Directory Service for a SaaS app's end users
> Directory Service is for **corporate/workforce** identity — employees, domain-joined machines, AD-aware applications. For a **consumer or SaaS application's own users**, including social sign-in and scaling to millions, the answer is **Amazon Cognito**. AWS's own guidance makes this split explicitly.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Written 2026-09-26 from a coverage audit** — these are the seven in-scope services the vault had missed. Not drilled or mocked yet.
- [ ] **DMS vs SCT** — the biggest single gap I had. DMS moves data, SCT converts schema; heterogeneous needs both.
- [ ] **Step Functions Standard vs Express** — five minutes and at-least-once are the two numbers that decide it.
- [ ] **The three Directory Service options** — RDS for SQL Server is the discriminator that collapses the choice.
- [ ] **Transfer Family vs DataSync** — protocol endpoint vs transfer job.

## 🔗 Docs
- [Working with AWS DMS Serverless](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Serverless.html)
- [DMS targets](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Targets.html) · [DMS sources](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.Sources.html)
- DMS + Snowball Edge: **chapter removed from the AWS DMS user guide** — no live citation exists. Mechanism from the [archived 2022 copy](https://web.archive.org/web/20221129212529/https://docs.aws.amazon.com/dms/latest/userguide/CHAP_LargeDBs.Process.html); retirement dates from [AWS Snowball Edge availability change](https://docs.aws.amazon.com/snowball/latest/developer-guide/snowball-edge-availability-change.html).

- [What is AWS DMS?](https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html) — replication instance, one-time vs ongoing replication, heterogeneous support, SCT / DMS Schema Conversion, Fleet Advisor, KMS/SSL; verified 2026-09-26
- [What is Step Functions?](https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html) — Standard vs Express table, the three integration patterns, state types; verified 2026-09-26
- [What is AWS AppSync?](https://docs.aws.amazon.com/appsync/latest/devguide/what-is-appsync.html) — GraphQL + Pub/Sub, WebSocket subscriptions, auth modes, caching; verified 2026-09-26
- [What is AWS Batch?](https://docs.aws.amazon.com/batch/latest/userguide/what-is-batch.html) — ECS/EKS, EC2/Fargate/Spot, fully managed batch; verified 2026-09-26
- [What is Elastic Beanstalk?](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/Welcome.html) — provisioning scope, supported platforms, **no additional charge**; verified 2026-09-26
- [What is AWS Transfer Family?](https://docs.aws.amazon.com/transfer/latest/userguide/what-is-aws-transfer-family.html) — SFTP/FTPS/FTP/AS2, S3 and EFS targets, 3 AZs, managed workflows; verified 2026-09-26
- [What is AWS Directory Service?](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/what_is.html) — the three options, edition object limits, Simple AD's unsupported features, RDS SQL Server compatibility, Cognito for SaaS; verified 2026-09-26
- [SAA-C03 Exam Guide (PDF)](https://d1.awsstatic.com/training-and-certification/docs-sa-assoc/AWS-Certified-Solutions-Architect-Associate_Exam-Guide.pdf) — the in-scope service list this note was audited against; verified 2026-09-26
