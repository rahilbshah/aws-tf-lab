---
topic: 12-storage-extras
domain: resilient
status: reviewed
services: [EFS, FSx, StorageGateway, DataSync, Snow, AWSBackup]
related: [09-s3-intro, 02-ec2, 05-vpc-hybrid, 07-rds-aurora]
cards: cards/12-storage-extras-cards
tags: [topic, domain/resilient]
---

# 12 – Storage extras (EFS, FSx, Storage Gateway, DataSync, Snow, Backup)

Everything in AWS storage that isn't S3 or EBS. Shared file systems, the bridge to on-premises, and the two ways to move bulk data in.

> [!warning] Build tier — **conceptual-only**
> EFS is nearly free at lab scale, but FSx, Storage Gateway and Snow all bill meaningfully and several take 20+ minutes to provision. This topic is learned from notes; the exam tests *which service you pick*, not the HCL.

## What problem does this solve?

You already have two kinds of storage. **EBS** is a disk bolted to one instance. **S3** is an object store you talk to over an API.

Between them sits a gap, and it's a big one: **a normal file system that several machines can mount at once.** Not an API — a mount point, with directories and POSIX permissions and file locking, that ten servers can write to simultaneously.

An EBS volume can't do that — it's a raw disk for one instance at a time (Multi-Attach shares *block*, not a file system, and only within one AZ). S3 can't either — your application would have to be rewritten to make API calls instead of opening files.

That gap is what **EFS** and **FSx** fill.

Then there's a second, unrelated gap. You have **data and systems that already exist**, in a building, on hardware you own. Sometimes you want to move it all in. Sometimes you can't move it at all, and you need on-premises systems to reach cloud storage as if it were local. **Storage Gateway**, **DataSync** and the **Snow Family** are the three answers to that, and they answer different questions.

> In one line: EBS is one disk for one server, S3 is an API, and everything in this note exists because real workloads need a shared file system or a bridge to a building.

## How it actually works

### Block, file, object — the distinction the exam is really testing

Almost every storage question is secretly asking which of three shapes you need.

| Shape | What you get | AWS service |
|---|---|---|
| **Block** | a raw disk you format yourself; one instance at a time | EBS, instance store |
| **File** | a mountable file system with directories, shared by many machines | **EFS, FSx** |
| **Object** | flat key → object, reached over an API | S3, Glacier |

The tell in a question is usually the verb. *"Mount"*, *"shared across instances"*, *"lift-and-shift an application that expects a file path"* → **file**. *"Upload/download"*, *"store and retrieve"* → **object**. *"Attach a volume"*, *"boot from"* → **block**.

> In one line: block is one disk for one server, file is one file system many servers mount, object is an API — and the question's verbs tell you which.

### EFS: the file system with no size

EFS is a **Linux** shared file system. Machines mount it over **NFS** (v4.1 and v4.0), and once mounted it behaves like any other directory tree.

Two things make it unusual, and both come up in questions.

**It has no capacity to provision.** You never say how big it should be. It grows as you add files and shrinks as you delete them, on to petabyte scale. Compare that with EBS, where you choose a size up front and pay for it whether you fill it or not.

**Lots of things can mount it at once** — EC2, ECS, EKS, Lambda and Fargate — and they can be spread across Availability Zones. That's the whole point: it is the shared file system EBS can't be.

The one restriction that catches people: **EFS is not supported with Windows EC2 instances.** AWS states this plainly. If the scenario says Windows, EFS is wrong no matter how well the rest of it fits — and that's what FSx for Windows File Server is for.

You choose an availability shape at creation:

- **Regional** (recommended) — data stored redundantly across several Availability Zones, so it survives losing one.
- **One Zone** — a single AZ, cheaper, and data may be lost if that zone is lost. The same trade you saw with S3 One Zone-IA in [[09-s3-intro]].

Storage classes work like S3's: **Standard** for active files, **Infrequent Access** for files touched rarely, **Archive** for files touched almost never — Standard and IA have One Zone variants, **Archive is Regional-only**. Lifecycle moves files *down* on last-access age (IA at 30 days, Archive at 90 by default). Moving them back up is **not** automatic: by default an accessed file stays in IA or Archive, and you only get promotion by setting the **Transition into Standard** policy to *On first access*.

Encryption at rest is enabled **at creation**; encryption in transit is enabled **when you mount**. Access is controlled by IAM and security groups on the network side, and POSIX permissions inside the file system.

> In one line: EFS is an elastic NFS file system many Linux machines mount at once — and it does not work with Windows.

### FSx: when the workload demands a *specific* file system

EFS gives you *a* file system. Sometimes the application demands *a particular one* — because it speaks SMB, or because it expects Lustre's performance. That's FSx: AWS running a real, named file system for you.

Four of them, and for the exam two matter most.

**FSx for Windows File Server** is a genuine Windows file server. It speaks **SMB**, authenticates users against **Microsoft Active Directory**, and enforces **Windows ACLs** on files and folders. That combination is the answer to every "we're lifting a Windows application into AWS" question. It offers **Single-AZ** or **Multi-AZ** (which keeps a standby file server in another AZ), SSD or HDD storage, and takes automatic daily backups made consistent with Windows' Volume Shadow Copy Service.

**FSx for Lustre** is for jobs where storage speed is the bottleneck — HPC, machine learning training, video processing, financial modelling. It delivers sub-millisecond latency and up to multiple TB/s of throughput. Its distinguishing trick is **S3 integration**: link a bucket and Lustre presents the objects in it as ordinary files, and can write results back. That's why it shows up in ML questions — you keep the dataset in S3 and get a fast POSIX file system over it for the duration of the job.

Lustre has two deployment types and the difference is durability, not speed:

- **Scratch** — data is **not replicated** and does not survive a file server failure. For temporary processing.
- **Persistent** — data is replicated and failed file servers are replaced automatically. For anything you'd be upset to lose.

The other two, in a line each: **FSx for NetApp ONTAP** speaks **both NFS and SMB**, which makes it the answer when Linux and Windows clients need the same data. **FSx for OpenZFS** speaks NFS and is built around cheap snapshots and clones.

> In one line: FSx is AWS running a named file system for you — Windows/SMB/Active Directory for lift-and-shift, Lustre for speed and S3-backed compute.

### Storage Gateway: making cloud storage look local

Some systems aren't moving. A tape backup process, an application that writes to an iSCSI volume, a workflow that expects an SMB share — rewriting them isn't on the table.

Storage Gateway is a **virtual appliance you run in your own data centre** (on VMware ESXi, KVM or Hyper-V), or as a hardware appliance, or as an EC2 instance. It presents a familiar local interface on one side and quietly stores the data in AWS on the other.

Four flavours, and they're named for what they *look like* locally:

- **S3 File Gateway** — looks like an **NFS or SMB share**; files land as objects in S3.
- **FSx File Gateway** — gives on-premises users low-latency access to files held in **FSx for Windows File Server**.
- **Volume Gateway** — looks like an **iSCSI disk**.
- **Tape Gateway** — looks like a **physical tape library**, so existing backup software keeps working while the tapes are virtual and stored in AWS.

Volume Gateway splits two ways, and this is the one worth being precise about because it's a favourite question. The difference is **where the primary copy lives**:

- **Cached volumes** — the primary data lives **in S3**. A subset of frequently-accessed data is kept locally for low latency. You use this to *stop growing* your on-premises storage.
- **Stored volumes** — the **entire dataset stays local**, and point-in-time snapshots are asynchronously backed up to S3. You use this when you need low-latency access to *everything* and want cheap offsite backups.

The tell: *"reduce on-premises storage footprint"* → **cached**. *"low-latency access to the entire dataset"* / *"offsite backup"* → **stored**.

> In one line: Storage Gateway is an on-prem appliance that looks like NFS, SMB, iSCSI or a tape library locally while storing in AWS — and for Volume Gateway, cached keeps the primary in S3 while stored keeps it on site.

### Moving bulk data in: over the wire, or in a truck

Two very different answers, and the discriminator is simple.

**DataSync** moves data **over the network**. It runs as an agent, reads from on-premises **NFS, SMB, HDFS or object storage** — and from other clouds — and writes to **S3, EFS, or any of the FSx file systems**. It encrypts in transit, **validates data integrity** on arrival, can run on a schedule rather than once, and can go through a VPC endpoint so the traffic never touches the public internet. That last set of properties is why it's the answer for *recurring* transfers, not just migrations.

**The Snow Family** moves data **physically**, on a rugged device AWS ships you. Snowball Edge comes Storage Optimized (210 TB) or Compute Optimized, encryption is enforced, and the devices can also run EC2 instances and Lambda at the edge — which is the other half of why they exist, for sites with poor connectivity.

> [!warning] Currency — Snowball Edge is closing to new customers
> AWS's own documentation now states that **Snowball Edge is no longer available to new customers**, and directs new users to **DataSync** for online transfer, **AWS Data Transfer Terminal** for physical transfer, or **AWS Outposts** for edge compute. SAA-C03 material almost certainly still tests Snow, so learn it — but know it is being wound down. (Verified 2026-09-05.)

> In one line: DataSync goes over the wire and can repeat on a schedule; Snow goes in a truck because the wire would take too long.

### AWS Backup: one place instead of six

Every service has its own backup mechanism — RDS automated backups, EBS snapshots, DynamoDB point-in-time recovery. Managing six of them separately is how gaps appear.

**AWS Backup** is a single control plane over all of it. You write a **backup plan** (a policy: what to back up, how often, how long to keep it), assign resources to it — often **by tag**, so anything tagged `Backup=daily` is automatically covered — and backups land in a **backup vault**.

The features that turn up in exam questions:

- **Cross-Region copy** for the "keep backups a minimum distance from production" requirement.
- **Cross-account copy**, which requires **AWS Organizations** ([[01-iam-advanced]]).
- **Lifecycle to cold storage**, so old backups get cheaper automatically.
- **AWS Backup Vault Lock**, which enforces **WORM** — no one can delete a backup or shorten its retention while the lock holds. **Governance mode** can be unlocked by anyone with the IAM permission; **compliance mode** cannot be, by anyone including AWS, once its grace time (minimum 3 days) expires. Same shape as S3 Object Lock in [[09-s3-security]].
- **Backup Audit Manager** for proving compliance.

It covers a wide spread: EC2, EBS, S3, RDS, Aurora, DynamoDB, EFS, all four FSx file systems, Storage Gateway volumes, DocumentDB, Neptune, Redshift, and more.

> In one line: AWS Backup is a policy engine over every service's own backups, with tag-based assignment, cross-Region and cross-account copies, and a vault lock that makes them WORM.

## Exam recap

> [!info] Exam TL;DR
> - **Block / file / object.** EBS = one disk, one instance. EFS + FSx = a shared file system many machines mount. S3 = an API. "Mount", "shared across instances" → file.
> - **EFS** = elastic **NFS** for **Linux**, mounted by many instances across AZs, no capacity to provision. **Not supported with Windows EC2 instances.** Regional vs One Zone; Standard / IA / Archive with lifecycle on last access.
> - **FSx for Windows File Server** = **SMB + Active Directory + Windows ACLs**. The lift-and-shift-a-Windows-app answer. Single-AZ or Multi-AZ.
> - **FSx for Lustre** = HPC/ML speed, sub-ms latency, **links to an S3 bucket and presents objects as files**. **Scratch** = not replicated; **Persistent** = replicated.
> - **FSx for NetApp ONTAP** = the one that speaks **both NFS and SMB**. **OpenZFS** = NFS with cheap snapshots/clones.
> - **Storage Gateway** = on-prem appliance. **S3 File Gateway** (NFS/SMB→S3) · **FSx File Gateway** · **Volume Gateway** (iSCSI) · **Tape Gateway** (virtual tape library).
> - **Volume Gateway: cached** = primary in **S3**, hot subset local (shrink on-prem storage). **stored** = primary **on-prem**, snapshots to S3 (low-latency for everything + offsite backup).
> - **DataSync** = over the network, agent-based, NFS/SMB/HDFS/object → S3/EFS/FSx, integrity-validated, schedulable. **Snow** = physical shipping when the network would take too long.
> - **AWS Backup** = central backup plans, tag-based assignment, cross-Region **and** cross-account (needs Organizations), and **Vault Lock = WORM**.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| EFS file system | `aws_efs_file_system` | `performance_mode`, `throughput_mode`, `lifecycle_policy`, `encrypted`. |
| Where it can be mounted | `aws_efs_mount_target` | **One per AZ**, each in a subnet with a security group. |
| Restrict a client to a subtree | `aws_efs_access_point` | Enforces a POSIX user and root directory per application. |
| FSx Windows | `aws_fsx_windows_file_system` | `active_directory_id` or `self_managed_active_directory`, `deployment_type`. |
| FSx Lustre | `aws_fsx_lustre_file_system` | `deployment_type` (SCRATCH_* / PERSISTENT_*), `import_path` for S3. |
| Storage Gateway | `aws_storagegateway_gateway` (+ `_cached_iscsi_volume`, `_nfs_file_share`, `_smb_file_share`) | `gateway_type` = FILE_S3 / FILE_FSX_SMB / CACHED / STORED / VTL. |
| DataSync | `aws_datasync_task` + `aws_datasync_location_*` | A task joins a source location to a destination location. |
| Backup policy | `aws_backup_plan` + `aws_backup_selection` | Selection can match **by tag**. |
| Backup destination | `aws_backup_vault` (+ `aws_backup_vault_lock_configuration`) | Vault Lock is the WORM control. |

## Key facts, limits & pricing

- **EFS** speaks **NFSv4.1 and NFSv4.0**. Mountable from EC2, ECS, EKS, Lambda and Fargate. Capacity is elastic to petabyte scale with nothing to provision. **Using EFS with Windows EC2 instances is not supported.**
- **EFS file system types:** *Regional* (recommended) stores data redundantly across several AZs; *One Zone* stores in a single AZ and data may be lost if that AZ is lost.
- **EFS defaults AWS recommends:** **General Purpose** performance mode (for latency-sensitive work like web serving, CMSes, home directories) and **Elastic** throughput mode (scales automatically with the workload).
- **EFS storage classes:** Standard, Infrequent Access, Archive. Standard and IA have One Zone variants; **Archive is Regional-only** and needs **Elastic** throughput. Lifecycle defaults: **IA at 30 days**, **Archive at 90 days** of no access. **Transition into Standard defaults to *None*** — an accessed file does **not** come back automatically (unlike Glacier, there is no restore job either; it is simply served from where it is).
- **EFS encryption:** at rest is enabled **at creation** (encrypts data *and* metadata); in transit is enabled **at mount time**. Network access via security groups + IAM; in-file-system permissions via POSIX.
- **FSx for Windows** speaks **SMB 2.0–3.1.1**, requires **Microsoft Active Directory**, and offers **Single-AZ or Multi-AZ** (Multi-AZ provisions a standby file server in another AZ). SSD and HDD storage; storage, SSD IOPS and throughput are provisioned independently. Encrypted at rest with KMS, in transit with SMB Kerberos session keys. Reachable from on-premises over **Direct Connect or Site-to-Site VPN**, and cross-VPC/account/Region via peering or Transit Gateway.
- **FSx for Lustre** is POSIX-compliant and **Linux-only** (needs the Lustre client). **Scratch** file systems are **not replicated** and do not survive a file server failure; **persistent** ones are replicated and failed servers are replaced. Storage classes: SSD, Intelligent-Tiering, HDD.
- **FSx for Lustre + S3:** linking a bucket presents its objects as files; Amazon FSx imports file listings at creation and can import later additions, and data can be written back to S3.
- **Storage Gateway** deploys as a VM on **VMware ESXi, KVM or Hyper-V**, as a hardware appliance, or as an **EC2 instance** (useful for DR and mirroring).
- **Volume Gateway is iSCSI.** *Cached*: data lives in **S3**, frequently-accessed subset retained locally. *Stored*: **all** data local, asynchronous point-in-time snapshots to S3, recoverable to your data centre **or to EC2**.
- **DataSync** sources: on-prem **NFS, SMB, HDFS, object storage**, and other clouds (Azure Blob/Files, Google Cloud Storage, and others). Destinations: **S3, EFS, FSx for Windows / Lustre / OpenZFS / NetApp ONTAP**. Includes **automatic encryption and data integrity validation**, supports **VPC endpoints** so traffic avoids the public internet, and uses a purpose-built parallel protocol.
- **Snowball Edge:** Storage Optimized **210 TB** or Compute Optimized; network adapters up to **100 Gbit/s**; encryption enforced at rest and in transit; devices can be **clustered (3–16)**; supports **NFSv3/v4/v4.1** and the S3 API. Can run EC2 instances and Lambda via IoT Greengrass at the edge. ⚠️ **No longer available to new customers** — AWS directs new users to DataSync, AWS Data Transfer Terminal, or Outposts (verified 2026-09-05).
- **AWS Backup** supports EC2, EBS, S3, RDS (all engines, incl. Multi-AZ clusters), Aurora, DynamoDB, EFS, all four FSx types, Storage Gateway volumes, DocumentDB, Neptune, Redshift, Timestream, EKS, CloudFormation, SAP HANA on EC2, and VMware Cloud on AWS. Backups are **incremental for supported resource types** (others are full copies each time — a real cost consideration). **Cross-account** backup requires an **AWS Organizations** structure.
- ⚠️ Pricing for EFS, FSx, Storage Gateway, DataSync and Snow changes; check current rates rather than memorising figures. The exam tests *service choice*, not price points.

## Comparisons

### EFS vs FSx vs EBS vs S3

|   | **EBS** | **EFS** | **FSx for Windows** | **FSx for Lustre** | **S3** |
|---|---|---|---|---|---|
| Shape | block | file | file | file | object |
| Protocol | — (attached disk) | **NFS** | **SMB** | Lustre | HTTP API |
| Shared by many instances | ❌ one at a time | ✅ | ✅ | ✅ | ✅ (API) |
| OS | any | **Linux only** | Windows (and Linux SMB clients) | **Linux only** | any |
| Capacity | provisioned | **elastic** | provisioned | provisioned | elastic |
| Reach for it when | boot volume, single-instance disk | shared Linux file system | Windows app, AD auth, SMB | HPC/ML speed, S3-backed compute | objects, static content, backup |

### Volume Gateway: cached vs stored

|   | **Cached volumes** | **Stored volumes** |
|---|---|---|
| Primary copy lives | **in S3** | **on premises** |
| Kept locally | frequently-accessed subset | the **entire** dataset |
| In AWS | all data | asynchronous point-in-time snapshots |
| Solves | on-prem storage keeps growing | need low-latency access to everything, plus offsite backup |

### Getting data in: DataSync vs Snow vs Storage Gateway

|   | **DataSync** | **Snow Family** | **Storage Gateway** |
|---|---|---|---|
| Moves data over | the network | a truck | the network, continuously |
| One-off or ongoing | one-off **or scheduled** | one-off | **ongoing** — it's a permanent bridge |
| Purpose | migrate / replicate / archive | migrate when the network can't cope | let on-prem systems *use* cloud storage |
| Tell | "transfer", "migrate", "sync on a schedule" | "petabytes", "poor connectivity", "would take months" | "keep the on-prem app unchanged", "tape", "iSCSI", "NFS/SMB share" |

## Worked examples

> [!example] Worked example — a web tier that needs shared uploads
> An application behind an ALB runs on an Auto Scaling group ([[04-alb-asg]]) and lets users upload files. Instances come and go, so anything written to an instance's EBS volume disappears with it, and two instances can't see each other's uploads. Attaching one EBS volume to all of them isn't possible — an EBS volume lives in a single AZ, and the ASG spans AZs. The fix is **EFS**: create the file system, create a **mount target in each AZ** the ASG spans, allow NFS from the instance security group, and mount it in `user_data`. The fix is **EFS**: create the file system, create a **mount target in each AZ** the ASG spans, allow NFS from the instance security group, and mount it in `user_data`. Every instance now sees the same directory, new instances pick it up automatically, and there is no capacity to manage. (In production you'd more likely put uploads in **S3** and skip the file system entirely — EFS is the answer when the application insists on file paths and can't be changed.)

> [!example] Worked example — lifting a Windows application into AWS
> A company runs a .NET application against a Windows file share, with permissions driven by Active Directory groups. They want it in AWS without rewriting it. EFS is out — it's NFS, and **AWS doesn't support EFS with Windows EC2 instances**. S3 is out — the app opens file paths, not APIs. The answer is **FSx for Windows File Server**: SMB, joined to Active Directory (either AWS Managed Microsoft AD or their own via AD Connector — see [[01-iam-advanced]]), enforcing the same Windows ACLs. Choose **Multi-AZ** so a zone failure doesn't take the share down. On-premises users can reach it over Direct Connect or Site-to-Site VPN ([[05-vpc-hybrid]]) during the migration.

> [!failure] Failure mode — Lustre scratch for data that mattered
> A team runs genomics processing on **FSx for Lustre**, picks the **scratch** deployment type because it's cheaper and faster, and writes results straight to it. A file server fails mid-run. Scratch file systems are **not replicated** and data does not persist through a file server failure — the results are gone, and there was no second copy. Two correct fixes: use a **persistent** file system for anything you'd be upset to lose, or keep the durable copy in **S3** and use Lustre as the fast working layer over it, writing results back. The second is the idiomatic pattern and the reason the S3 link exists.

## Traps

> [!warning] Trap — EFS for a Windows workload
> The most reliable elimination in this topic. **AWS does not support EFS with Windows EC2 instances.** Any question mentioning Windows, SMB, Active Directory, or Windows ACLs is pointing at **FSx for Windows File Server**, however well "shared file system" seems to fit EFS.

> [!warning] Trap — cached vs stored Volume Gateway, reversed
> Read where the *primary* copy lives. **Cached** = primary in S3, hot subset local — chosen to stop on-premises storage growing. **Stored** = primary on-premises, snapshots to S3 — chosen when you need low-latency access to the *whole* dataset and want offsite backups. The words are unhelpfully similar; anchor on "which copy is authoritative".

> [!warning] Trap — DataSync vs Storage Gateway
> Both move data between on-premises and AWS, and both need something installed locally. **DataSync transfers data** — a migration or a scheduled sync, after which the job is done. **Storage Gateway is a permanent bridge** — the on-premises system keeps using it every day as if it were local storage. "Migrate 50 TB to S3" → DataSync. "Our backup software must keep writing to tape" → Tape Gateway.

> [!warning] Trap — Snow when the network would do
> Snow exists for data volumes where transferring over the network would take impractically long, or where connectivity is poor. It is not the answer to "we have 5 TB to move" on a decent link — that's **DataSync**. And note the currency point: **Snowball Edge is closed to new customers**, with AWS pointing to DataSync, AWS Data Transfer Terminal, or Outposts.

> [!warning] Trap — Lustre scratch vs persistent read as a speed choice
> The difference is **durability**, not performance. Scratch is **not replicated** and does not survive a file server failure; persistent is replicated with automatic server replacement. If the question mentions long-running work or data you can't re-create, it's persistent.

> [!warning] Trap — "EFS One Zone is fine, it's still durable"
> Same shape as the S3 One Zone-IA trap in [[09-s3-intro]]. One Zone stores in a single Availability Zone, and data may be lost if that zone is lost. It's for data you could re-create, not for the only copy.

> [!example]- Recall drill
> (1) Which storage service can't be used with Windows EC2 instances, and what replaces it? (2) Volume Gateway cached vs stored — where does the primary copy live in each? (3) FSx for Lustre scratch vs persistent — what actually differs? (4) DataSync or Storage Gateway for "our tape backup software must keep working"? (5) Which FSx speaks both NFS and SMB? (6) What does AWS Backup Vault Lock give you, and what does cross-account backup require?
> > [!success]- Answers
> > (1) EFS — it's NFS/Linux only; use FSx for Windows File Server. (2) Cached = primary in S3 with a hot subset local; stored = primary on-premises with snapshots to S3. (3) Durability — scratch isn't replicated and doesn't survive a file server failure. (4) Storage Gateway, specifically **Tape Gateway**. (5) FSx for NetApp ONTAP. (6) WORM immutability on backups; cross-account requires AWS Organizations.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Never studied** — written 2026-09-05 without an orientation pass; nothing here has been tested against a mock yet.
- [ ] **EFS is Linux-only** — the single highest-value elimination in the topic.
- [ ] **Volume Gateway cached vs stored** — anchor on which copy is authoritative, not on the word.
- [ ] **DataSync (a transfer) vs Storage Gateway (a permanent bridge).**
- [ ] **Lustre scratch vs persistent is a durability choice**, not a speed one.

## 🔗 Docs

- [What is Amazon EFS](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) — NFSv4.1/4.0, Regional vs One Zone, General Purpose + Elastic defaults, encryption, and the explicit "not supported with Windows EC2 instances"; verified 2026-09-05
- [EFS storage classes](https://docs.aws.amazon.com/efs/latest/ug/storage-classes.html) — Standard / IA / Archive + One Zone variants, lifecycle on last access; verified 2026-09-05
- [What is FSx for Windows File Server](https://docs.aws.amazon.com/fsx/latest/WindowsGuide/what-is.html) — SMB 2.0–3.1.1, Active Directory, Single-AZ vs Multi-AZ, SSD/HDD, VSS backups, on-prem access via DX/VPN; verified 2026-09-05
- [What is FSx for Lustre](https://docs.aws.amazon.com/fsx/latest/LustreGuide/what-is.html) — scratch vs persistent durability, storage classes, S3 data-repository integration; verified 2026-09-05
- [What is Volume Gateway](https://docs.aws.amazon.com/storagegateway/latest/vgw/WhatIsStorageGateway.html) — cached vs stored, iSCSI, deployment options; verified 2026-09-05
- [What is AWS DataSync](https://docs.aws.amazon.com/datasync/latest/userguide/what-is-datasync.html) — sources/destinations, integrity validation, VPC endpoints; verified 2026-09-05
- [What is Snowball Edge](https://docs.aws.amazon.com/snowball/latest/developer-guide/whatisedge.html) — 210 TB Storage Optimized, clustering, protocols, **and the notice that it is closed to new customers**; verified 2026-09-05
- [What is AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html) — backup plans/vaults, tag-based assignment, cross-Region and cross-account, Vault Lock WORM, supported services; verified 2026-09-05
- [Terraform `aws_efs_file_system`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) / [`aws_fsx_windows_file_system`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_windows_file_system) / [`aws_backup_plan`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan)

---
**Cards for this topic:** [[cards/12-storage-extras-cards]]
