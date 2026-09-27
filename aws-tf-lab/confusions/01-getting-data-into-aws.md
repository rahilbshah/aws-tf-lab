---
confusion: 01-getting-data-into-aws
spans: [12-storage-extras, 24-other-services, 09-s3-advanced]
services: [TransferFamily, DataSync, StorageGateway, Snow, S3Replication]
tags: [confusion, domain/performance]
---

# Confusion 01 — Getting data into AWS

> [!info] What this is, and how to use it
> Not a summary. Every item asks you to **commit to an answer before you read on**,
> and the answer's job is to hand you a **rule**, not a verdict.
> The members deliberately come from **different notes** — the exam doesn't respect
> your folder structure, and neither do the distractors.

## Why these five collide

Five services move bytes from somewhere-else into AWS. Read their one-line
descriptions and they sound almost interchangeable — all of them "transfer data
to S3". That's why exam writers put three of them in the same question.

They are not variations on a theme. They answer **five different questions**, and
once you can hear which question a scenario is asking, the other four options
stop being tempting.

## The two questions that decide every one of these

Ask these in order. You will almost never need a third.

**Question 1 — where are the two ends?**

| Where the two ends are | Answer |
|---|---|
| Both ends already in AWS | **S3 Replication** (CRR/SRR) |
| An outside party pushes to you | **Transfer Family** |
| Your on-premises systems, you move the data | **DataSync** or **Snow** |
| Your on-premises systems, and they *keep running there* | **Storage Gateway** |

**Question 2 — when this is finished, what is still running?**

This is the one that separates the pair people actually confuse.

- **DataSync**: *nothing*. It was a job. It copied a dataset and ended.
- **Storage Gateway**: *an appliance, forever*. Nothing was "moved" — your on-prem
  application still reads and writes locally, and AWS is quietly the backing store.
- **Transfer Family**: *an endpoint, forever*. Partners keep connecting to it.

A migration ends. A hybrid arrangement doesn't. **"Migrate" → DataSync. "Continue
to access" → Storage Gateway.**

---

## Drills

Commit out loud before you unfold. If you can't commit, that's the useful signal —
unfold and read the axis rather than guessing.

**1.** A logistics company's trading partners send shipment files several times a day
over SFTP. The partners are external businesses with their own scripts and firewall
rules, and they will not change them. The files need to land in S3 for processing.

> [!success]- The axis
> **AWS Transfer Family.**
> **Axis:** Question 1 — *an outside party pushes to you*. The tell is "partners,
> with their own clients, that won't change." You need a **standing protocol
> endpoint** they can point at.
> **Why the neighbours die:** **DataSync** is a job *you* initiate against storage
> *you* control — it has no notion of a third party connecting inbound, and it
> doesn't speak SFTP. **Storage Gateway** is an appliance in *your* data centre;
> your partners aren't in your data centre.
> **What would flip it:** if the same files were sitting on an NFS share inside your
> own data centre and you wanted them copied nightly, it becomes **DataSync**. The
> bytes are identical — only *who initiates* changed.
> *Sources: [[24-other-services]] · [[12-storage-extras]]*

**2.** A hospital's imaging archive holds 600 TB on-premises. The site's internet
connection is slow and unreliable. The archive must end up in S3.

> [!success]- The axis
> **Physical transfer** — historically **Snowball Edge**, but check the date.
> **Axis:** network capacity, not service preference. The question is arithmetic:
> 600 TB ≈ 4.8 million gigabits; at a *sustained* 1 Gbps that's roughly **55 days**.
> Shipping a device beats that.
> **⚠️ Currency:** **Snowball Edge is no longer available to new customers.** AWS
> directs new users to **DataSync**, **AWS Data Transfer Terminal**, or **Outposts**
> (verified 2026-09-05). On the exam, Snow is still the intended answer for
> "huge dataset, poor connectivity" — in real life it isn't available to you.
> **What would flip it:** a 10 Gbps dedicated link changes the arithmetic to a few
> days and **DataSync** wins. Always do the division before picking Snow.
> *Sources: [[12-storage-extras]]*

**3.** A media company keeps 40 TB of active project files on an on-premises NAS.
Editors need to keep working against that NAS at local speed, but the company wants
to stop buying disk shelves and have the bulk of the data live in AWS.

> [!success]- The axis
> **Storage Gateway — Volume Gateway, *cached* mode.**
> **Axis:** Question 2 — *the workload stays on-premises*. Nobody is migrating;
> editors keep using local storage forever. That's an appliance, not a job.
> **Cached vs stored is the sub-axis, and it's about where the *primary* copy lives:**
> **cached** = primary in **S3**, hot subset kept local — which is what "stop buying
> disk shelves" asks for. **stored** = *all* data stays local with snapshots to S3,
> which shrinks nothing.
> **Why the neighbours die:** **DataSync** would copy the files to AWS and end,
> leaving the editors with nothing local to work against.
> **What would flip it:** change the requirement to "editors need low-latency access
> to *everything* and we want offsite backup" and it becomes **stored** mode — same
> service, opposite configuration.
> *Sources: [[12-storage-extras]]*

**4.** A company's compliance team requires a copy of an audit-log bucket held in a
second AWS Region, at least 500 km away.

> [!success]- The axis
> **S3 Cross-Region Replication (CRR).**
> **Axis:** Question 1 — *both ends are already in AWS*. Nothing here is hybrid, so
> four of the five options are structurally impossible.
> **The two requirements that are always tested with it:** versioning must be enabled
> on **both** buckets, and S3 needs an **IAM role** to do the copying. Replication is
> **asynchronous**.
> **Why the neighbours die:** **DataSync** *can* move S3→S3, which is why it appears
> as a distractor — but it's a job you schedule, so a new object isn't copied until
> the next run. CRR is continuous. If the question says "automatically" or "as
> objects are created", it's replication.
> **What would flip it:** same requirement but the source is an on-premises object
> store → **DataSync**, which does speak object storage.
> *Sources: [[09-s3-advanced]] · [[12-storage-extras]]*

**5.** A bank runs backup software that writes to a physical tape library. The tapes
are expensive and the off-site rotation is manual. They want the tapes gone without
replacing the backup software.

> [!success]- The axis
> **Storage Gateway — Tape Gateway.**
> **Axis:** Question 2 — *"without replacing the backup software"*. The existing
> system must keep believing it is writing to tape, which means the local protocol
> has to be preserved. That's the entire purpose of Storage Gateway: present a
> familiar local interface, store in AWS.
> **The family, by the local protocol it imitates:** **S3 File Gateway** = NFS/SMB
> share → objects in S3. **FSx File Gateway** = low-latency on-prem access to FSx for
> Windows. **Volume Gateway** = iSCSI disk. **Tape Gateway** = virtual tape library.
> **What would flip it:** if they *were* willing to replace the backup software, this
> becomes an **AWS Backup** question and the gateway disappears.
> *Sources: [[12-storage-extras]]*

**6.** A retailer is decommissioning a data centre. 30 TB sits on an SMB file share
and must be in Amazon FSx for Windows File Server before the lease ends in a month.
They have a 1 Gbps connection.

> [!success]- The axis
> **AWS DataSync.**
> **Axis:** Question 2 — *this ends*. The data centre is going away, so there's no
> ongoing hybrid access to preserve; it's a migration with a deadline.
> **Check the arithmetic:** 30 TB ≈ 240,000 Gb; at a sustained 1 Gbps that's roughly
> **2.8 days** of pure transfer. Comfortably inside a month, so Snow isn't needed.
> **The detail worth knowing:** DataSync's destinations include **S3, EFS, and all
> four FSx types** — people assume it only targets S3 and rule it out wrongly here.
> Its sources include **NFS, SMB, HDFS, object storage** and other clouds.
> **What would flip it:** make it 600 TB or the link unreliable → physical transfer.
> Make the data centre *stay* → Storage Gateway.
> *Sources: [[12-storage-extras]]*

**7.** A manufacturer must exchange purchase orders with a supplier using a protocol
that provides receipts and non-repudiation for each message, as required by their
trading agreement.

> [!success]- The axis
> **AWS Transfer Family — AS2.**
> **Axis:** the protocol is named in the requirement. **AS2** is the B2B/EDI protocol;
> "trading partner", "supply chain", "purchase orders", "receipts/non-repudiation"
> are its signals.
> **Why this one is worth a slot:** AS2 is the least-known member of the Transfer
> Family set (alongside SFTP, FTPS, FTP and browser-based transfers), and B2B wording
> pushes candidates toward a messaging service instead.
> **Why the neighbours die:** **SQS/SNS/EventBridge** move *messages between your own
> components*, not files between companies under a trading agreement.
> *Sources: [[24-other-services]]*

---

## Where the rule breaks

Two honest boundary cases, so you don't over-apply the axis:

**DataSync and Storage Gateway can appear together.** A real migration often runs
DataSync for the bulk copy *and* leaves a File Gateway behind for the applications
that can't move yet. If a question offers "both", check whether it describes two
distinct needs — a one-time move *and* continuing local access.

**"Transfer Family vs DataSync" isn't always about protocol.** Both can end at S3.
The reliable separator is **who initiates**: an outside party with their own client
(Transfer Family) versus you, on a schedule (DataSync). Protocol is a strong hint,
not the rule — DataSync also speaks SMB and NFS, which are protocols too.

## The five, on one line each

Read this only *after* the drills — it's a check, not a substitute.

| Service | The question it answers |
|---|---|
| **Transfer Family** | "Outsiders push files to us and can't change their client." |
| **DataSync** | "We are moving a dataset, and then we're done." |
| **Storage Gateway** | "Our on-prem systems keep working locally; AWS is the backing store." |
| **Snow** | "The network cannot carry this in the time we have." |
| **S3 Replication** | "Both ends are already S3, and it must be continuous." |

## 🔗 Source notes

- [[12-storage-extras]] — Storage Gateway types, Volume Gateway cached vs stored, DataSync sources/destinations, Snow capacities and the closed-to-new-customers note
- [[24-other-services]] — Transfer Family protocols, S3/EFS targets, Transfer Family vs DataSync
- [[09-s3-advanced]] — CRR/SRR, versioning-both-sides, IAM role, async, delete-marker behaviour
