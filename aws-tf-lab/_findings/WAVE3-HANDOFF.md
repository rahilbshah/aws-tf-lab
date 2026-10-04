# Wave 3 findings — HANDOFF (not yet applied)

> **UPDATE 2026-10-04: verification is COMPLETE. 0 unverified remain.**
> The 43 outstanding claims were checked by a verify-only run (`wf_4548005a-7eb`):
> **18 confirmed, 25 overturned — a 58% overturn rate**, the highest of any stage.
> Final wave-3 tally: **232 claims → 131 CONFIRMED, 101 OVERTURNED**
> (30 high value · 91 medium · 10 low), including **6 contradictions**.
>
> That 58% is the point: had those 43 been written up unverified, **more than half would
> have been wrong** — duplicating text that already exists or inventing gaps. The overturn
> rate across the whole hunt ran 4% → 24% → 40% → 58%, climbing as coverage moved to a
> cheaper model and the verifier was told to expect over-flagging. The verify stage is not
> overhead; it is what makes the survivors worth writing.
>
> Four high-value additions from this last pass:
> - **`15-decoupling`** — EventBridge is the only option with **SaaS partner event sources
>   and event buses**. That note has *zero* occurrences of EventBridge, its frontmatter is
>   `services: [SQS, SNS, AmazonMQ]`, and its routing table at :204 actively sends the
>   reader to SNS. A gap and a mis-steer in one.
> - **`04-alb-asg`** — **SNI** lets one ALB listener hold several certificates, chosen per
>   hostname; a wildcard cert covers only subdomains of *one* domain. "SNI" appears nowhere
>   in the vault, and the note pushes the HTTP→HTTPS redirect hard, priming the wrong
>   distractor. Two bank questions turn on this.
> - **`02-ec2`** — **EBS Recycle Bin retention rules** recover deleted snapshots. The
>   vault's entire deletion vocabulary is *prevention* (Object Lock, Vault Lock), never
>   *recovery*.
> - **`07-rds-aurora`** — multi-hop relationship traversal (friends-of-friends) is a graph
>   workload → **Neptune**, not Aurora/Redshift/OpenSearch.

Harvested 2026-10-03 from workflow `wf_6f05199c-6e9`, stopped at 97% session usage with
all 22 coverage batches complete and 189 of 232 verifications done.

**Nothing here has been written into the notes.** The vault is unchanged.

## Numbers

- claims: **232** from 545 questions (the last of the 920-question clean pool)
- **CONFIRMED 113** · OVERTURNED 76 · **unverified 43**
- overturn rate on what was verified: **40%** (wave 1 was 4%, wave 2 24%)
- confirmed by value: {'medium': 77, 'high': 26, 'low': 10}
- confirmed by verdict: {'PARTIAL': 46, 'ABSENT': 61, 'CONTRADICTS': 6}
- **77 of 113** confirmed findings span 2+ notes (the seam problem)

## Do these first — 6 confirmed CONTRADICTIONS
A contradiction is worse than a gap: the note actively steers you to the wrong option.

### `22-analytics.md` — 2025-4-T6-Q06
- **Deciding fact:** AWS Glue ETL jobs run Apache Spark under the hood, so a Spark-on-S3 batch job can run on Glue (serverless) as well as EMR.
- **The note currently says:** 22-analytics.md:39 'You need to know that Spark means EMR, that SQL-on-S3 means Athena, and that "least operational overhead" almost always means the serverless one.' This sends a reader to EMR alone for 'Spark' and never says Glue jobs are Spark. Also 22-analytics.md:22 'EMR = managed Hadoop/Spark'.

### `09-s3-advanced` — 2025-4-T3-Q37
- **Deciding fact:** S3 Transfer Acceleration speeds BOTH uploads and downloads of large objects for geographically dispersed users, so it beats CloudFront when the requirement covers up/download of 10 GB files.
- **The note currently says:** 09-s3-advanced.md:90 'The distinction that gets tested: this is about **uploads**. If the scenario is serving *reads* to a global audience, the answer is **CloudFront**'; also 11-cloudfront.md:148 table 'speeds S3 **uploads** via an edge' and 09-s3-advanced.md:201 trap.

### `20-monitoring.md` — 2025-4-T2-Q09
- **Deciding fact:** For third-party certificates imported into ACM, an AWS Config managed rule (acm-certificate-expiration-check) with SNS is the least-effort 30-day expiry notification.
- **The note currently says:** 20-monitoring.md:305-306 'Eliminate: **AWS Config** "manually created rule checking certificate expiry" (Config evaluates configuration, and the stem's own wording gives it away)' - a reader would reject the Config managed-rule option that this question marks correct.

### `12-storage-extras` — 2025-7-T1-Q22
- **Deciding fact:** The stem needs low-latency BLOCK storage over iSCSI with Multi-AZ HA for Windows, and only FSx for NetApp ONTAP offers Multi-AZ plus iSCSI block; FSx for Windows is SMB file only.
- **The note currently says:** 12-storage-extras.md:87: "That combination is the answer to every "we're lifting a Windows application into AWS" question." (also 12-storage-extras.md:19 and :96 describe ONTAP only as "both NFS and SMB", never iSCSI/block)

### `02-ec2.md` — 2025-7-T5-Q43
- **Deciding fact:** t3a.medium is burstable and cannot use EFA (and EFA is not for Windows here); plain ENA enhanced networking is free, supported, and delivers the bandwidth/PPS/latency gain, so ENA beats EFA.
- **The note currently says:** 02-ec2.md:166-167: "EFA questions always carry 'tightly coupled HPC' wording, and the right answer pairs it with a **cluster** group." (plus 02-ec2.md:232 'EFA belongs with a cluster placement group'). This stem says HPC and cluster, so a reader picks EFA (B), but ENA is correct. The note never says EFA needs supported instance types.

### `22-analytics.md` — #7 2025-8-T3-Q33
- **Deciding fact:** Lake Formation builds the data lake and ingests data from RDS databases (blueprints, bulk and incremental); S3 alone is just storage with no ingestion.
- **The note currently says:** 22-analytics.md:176 'AWS Lake Formation is an authorization layer ... it does not store data itself.' and 22-analytics.md:24 'Lake Formation = fine-grained permissions layer over the Glue Data Catalog' (describes only permissions, steers reader to S3 when asked which service builds a centralized data repository / imports from RDS)

## Then: the 26 high-value gaps

| note | qid | discriminator |
|---|---|---|
| `19-serverless.md` | 2025-8-T2-Q33 | Enable DynamoDB Streams and trigger Lambda, which publishes to SNS, to alert on new items without touching the app; this is the native low-overhead ch |
| `02-ec2.md` | 2025-7-T2-Q12 | A secondary ENI keeps its private IP and can be detached and re-attached to a standby instance, so traffic resumes on the replacement; an EIP does not |
| `02-ec2` | 2025-4-T3-Q27 | gp2 tops out at 16,000 IOPS/volume while io1 provisions up to 64,000, so 25,000 IOPS per volume requires Provisioned IOPS io1. |
| `09-s3-advanced.md` | 2025-4-T1-Q51 | S3 request-rate limits (3,500 write / 5,500 read per second) apply per prefix, so spread keys across prefixes within one bucket rather than more bucke |
| `05-vpc-endpoints-peering.md` | 2025-8-T5-Q40 | A security group rule cannot reference a peer VPC's security group across Regions (inter-Region peering), so the DB rule must use the app servers' IP/ |
| `19-serverless.md` | 2025-4-T4-Q62 | DynamoDB on-demand mode absorbs sudden unpredictable spikes instantly and costs nothing idle; provisioned + auto scaling reacts only after CloudWatch  |
| `15-decoupling` | 2025-7-T2-Q17 | SQS has no message priority attribute; priority is done with separate queues (premium and free) with consumers polling the premium queue first. |
| `05-vpc-hybrid.md` | 2025-4-T6-Q12 | Maximum DX resiliency = separate connections on separate devices in more than one DX location; one connection per location is only high resiliency, tw |
| `04-alb-asg.md` | 2025-7-T3-Q48 | An ALB listener supports multiple certificates via SNI, which picks the right cert per hostname at no extra charge; no wildcard, SAN or new CloudFront |
| `02-ec2.md` | 2025-7-T2-Q23 | EBS supports live Elastic Volumes changes (type, size, IOPS) with no downtime and persists independently of the instance; replication is within the AZ |
| `02-ec2.md` | 2025-7-T3-Q20-hibernation | Hibernation must be enabled at launch, so the fix is to launch/migrate to a hibernation-enabled instance rather than flipping the setting on the exist |
| `02-ec2.md (EBS section), seam with 21-security.md` | #6 2025-7-T6-Q60 | EBS encryption by default is a per-Region account setting that auto-encrypts new volumes, including ones restored from unencrypted snapshots and snaps |
| `19-serverless.md` | #5 2025-7-T6-Q59 | A Lambda function URL is a built-in dedicated HTTPS endpoint, so a third-party webhook can call the function directly without API Gateway. |
| `15-decoupling.md` | #12 2025-8-T1-Q21 | SQS has no message priority, not even in FIFO. To prioritize, use a separate queue per tier and have consumers poll the paid queue first. |
| `09-s3-intro.md` | 2025-7-T5-Q51 | S3 supports at least 3,500 PUT/POST/DELETE and 5,500 GET/HEAD requests per second per prefix with no key-name randomization needed, so do nothing. |
| `24-other-services.md` | #11 2025-8-T4-Q07 | Tightly coupled MPI HPC with minimal ops is AWS Batch multi-node parallel jobs (single job across multiple EC2 instances), not ASG/CloudFormation plac |
| `24-other-services.md` | #2 2025-8-T1-Q40 | Batch plus Step Functions orchestration is least overhead; Fargate+SQS adds orchestration complexity. |
| `02-ec2.md` | 2025-8-T6-Q06 | sc1 (Cold HDD) is the cheapest EBS type, for infrequently accessed sequential throughput data; st1 is HDD but costlier and for frequent throughput wor |
| `02-ec2.md` | 2025-8-T6-Q09 | io1/io2 Provisioned IOPS SSD gives the most consistent low-latency performance for sustained high-IOPS databases; gp2 is burst/credit based and HDD ty |
| `20-monitoring.md` | 2025-8-T5-Q27 | An EventBridge rule can match 'AWS API Call via CloudTrail' events (e.g. ec2 CreateImage) and target SNS directly, with less overhead than Lambda/Athe |

## The 43 unverified claims — RESOLVED

All 43 were verified on 2026-10-04. 18 confirmed (now folded into the counts above), 25
overturned. Nothing is left unverified; `wave3-harvest.json` carries the final verdict on
every record.

## Status

The gap hunt is **finished**: 920 of 920 clean questions audited, every claim verified.
There is no wave 4. The only remaining use of the bank is the caveat harvest (Stage 0b of
`_scripts/GAP_WORKFLOW_PLAN.md`) over the 223 caveated questions — a currency feed, never a
source of facts.

**Writing order:** the 6 contradictions first (a wrong fact costs more than a missing one),
then the 30 high-value gaps, then decide on the 91 medium.

## Rules that apply when writing any of this up

- Verify every fact against first-party AWS docs **before** it goes in (§13.10).
- Check a doc page is live by fetching its `.md` twin and comparing size to the ~2,328-byte
  not-found shell — a `.md` 404 alone proves nothing.
- Unverifiable claims go in as `⚠️ verify:`, never as assertions.
- Question ids stay OUT of the notes (§13.12); they belong here and in commit messages.