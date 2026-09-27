---
decision: storage
question: Where should this data live?
spans: [02-ec2, 09-s3-intro, 09-s3-advanced, 12-storage-extras]
tags: [decision, domain/performance]
---

# Where should this data live?

The notes explain each storage service. This routes you to one. Work top-down —
the first question that applies settles it, and you rarely need more than two.

## 1. What shape does the application need?

The deciding question is **can the application be changed?** An app that calls
`open()` and `write()` on a path needs block or file storage. Only an app that can
call an API can use S3 — which is why "modernise to use S3" is a different answer
from "give it storage".

| The app wants | Shape | Go to |
|---|---|---|
| a disk it formats and mounts itself | **block** | §2 |
| a shared filesystem, several machines at once | **file** | §3 |
| to `PUT`/`GET` over HTTP | **object** | §4 |

## 2. Block — EBS or instance store

One question: **must the data survive a stop?**

- **Yes** → **EBS**. Network-attached, persists, AZ-scoped.
- **No, and local speed is the point** → **instance store**. Local NVMe, faster, and
  it dies on **stop *and* terminate** — not just terminate.
- **Several instances need the same volume** → `io1`/`io2` **Multi-Attach**, up to
  **16** instances, **same AZ only**. If they're in different AZs, you needed §3.

↳ [[02-ec2#EBS vs Instance Store]]

## 3. File — which one depends on the protocol, not the workload

| The application speaks | Answer |
|---|---|
| **NFS**, Linux clients | **EFS** — elastic, multi-AZ, nothing to provision |
| **SMB** + Active Directory | **FSx for Windows** |
| **both** NFS and SMB | **FSx for NetApp ONTAP** |
| Lustre — storage speed is the bottleneck (HPC, ML training) | **FSx for Lustre** |

**EFS is not supported with Windows EC2 instances.** That single fact resolves most
questions that mention Windows anywhere.

For EFS and FSx alike, **One Zone** is the cheaper single-AZ variant, and the trade
is the same one S3 makes: lose the AZ, lose the data.

↳ [[12-storage-extras#EFS vs FSx vs EBS vs S3]]

## 4. Object — which S3 class

Durability is **eleven nines in every class** and never decides anything. What
differs is **availability and AZ count**. Two questions settle it:

**How often is it read, and how fast must it come back?**

| Pattern | Class | Minimum duration |
|---|---|---|
| Hot, or unpredictable | Standard · **Intelligent-Tiering** | none |
| Rarely read, needed **instantly** | Standard-IA | **30 days** |
| Rarely read **and re-creatable** | One Zone-IA | **30 days** |
| Archive, needed instantly | Glacier Instant Retrieval | **90 days** |
| Archive, minutes to hours is fine | Glacier Flexible Retrieval | **90 days** |
| Deep archive, hours is fine | Glacier Deep Archive | **180 days** |

**Unpredictable access is the tell for Intelligent-Tiering** — it is the only class
with no minimum duration, so it is the safe answer when the pattern is unknown.

↳ [[09-s3-intro#Storage classes (verified against AWS docs 2026-08)|Storage classes]] · [[09-s3-advanced#Glacier retrieval tiers (verified)]]

## 5. Is on-premises involved?

Ask **what is still running when this finishes?**

| Situation | Answer | Still running after |
|---|---|---|
| On-prem apps keep using local NFS/SMB/iSCSI/tape | **Storage Gateway** | an appliance, permanently |
| Move a dataset once, or on a schedule | **DataSync** | nothing — the job ended |
| Outside partners push files with their own clients | **Transfer Family** | an endpoint, permanently |
| The network cannot carry it in the time available | **Snow** | nothing — the device went back |

Do the arithmetic before choosing Snow: 30 TB over a sustained 1 Gbps is under
3 days; 600 TB is about 55.

↳ [[12-storage-extras#Getting data in: DataSync vs Snow vs Storage Gateway]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **One Zone-IA's eleven nines.** Durability is what the class is *designed for*, not
  a promise it survives losing the AZ. Only put re-creatable data there.
- **Minimum duration is billed even if you delete.** Move an object to Glacier and
  delete it a week later and you still pay 90 days. Lifecycle rules that churn
  through tiers cost more than leaving data in Standard.
- **The 128 KB minimum billable object size** on Standard-IA, One Zone-IA and Glacier
  Instant. A million 4 KB files in IA costs *more* than Standard.
- **Instance store does not survive a stop.** Not just terminate — stop as well.
- **DataSync versus Storage Gateway.** A migration ends; a hybrid bridge doesn't.
  "Migrate" → DataSync. "Continue to access" → Storage Gateway.
- **Multi-Attach is same-AZ.** Cross-AZ shared block storage does not exist; that
  requirement means a file system.
