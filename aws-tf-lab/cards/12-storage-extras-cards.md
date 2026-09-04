---
topic: 12-storage-extras
domain: resilient
related_note: 12-storage-extras
tags: [flashcards/storage]
---

# Cards for [[12-storage-extras]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

Block vs file vs object — which AWS services, and what's the tell in a question?
?
Block = a raw disk for one instance at a time (EBS, instance store). File = a mountable shared file system many machines use at once (EFS, FSx). Object = flat key→object over an API (S3, Glacier). The verbs give it away: "mount" / "shared across instances" / "app expects a file path" → file. "Upload/download" → object. "Attach a volume" / "boot from" → block.

What protocol does EFS use, and what is the single biggest restriction?
?
NFS (v4.1 and v4.0). The restriction: **AWS does not support EFS with Windows EC2 instances.** Any scenario mentioning Windows, SMB, Active Directory or Windows ACLs means FSx for Windows File Server, no matter how well "shared file system" seems to fit.

What makes EFS different from EBS in capacity terms?
?
There is nothing to provision. EFS grows and shrinks automatically as you add and remove files, to petabyte scale. EBS is a fixed size you choose up front and pay for whether you fill it or not. EFS can also be mounted concurrently by EC2, ECS, EKS, Lambda and Fargate across multiple AZs; an EBS volume attaches to one instance.

EFS Regional vs One Zone?
?
Regional (recommended) stores data redundantly across several Availability Zones, so it survives losing one. One Zone stores in a single AZ, costs less, and data may be lost if that AZ is lost — the same trade as S3 One Zone-IA. One Zone is for data you can re-create, not the only copy.

What are the EFS storage classes and how do files move between them?
?
Standard, Infrequent Access, and Archive, each with a One Zone variant. EFS Lifecycle Management transitions files based on LAST ACCESS TIME, and reading an archived file transitions it back automatically — unlike Glacier, you don't issue a restore.

What defines FSx for Windows File Server?
?
SMB protocol (2.0–3.1.1), authentication against Microsoft Active Directory, and Windows ACLs on files and folders. That combination is the answer to any "lift a Windows application into AWS" question. Single-AZ or Multi-AZ (which keeps a standby file server in another AZ), SSD or HDD storage, daily backups made consistent with Volume Shadow Copy Service.

What is FSx for Lustre for, and what is its trick with S3?
?
Workloads where storage speed is the bottleneck — HPC, machine learning training, video processing, financial modelling. Sub-millisecond latency, up to multiple TB/s. The trick: link an S3 bucket and Lustre presents those objects as ordinary files, and can write results back. That's why it appears in ML questions — keep the dataset durable in S3, get a fast POSIX file system over it for the job.

FSx for Lustre: scratch vs persistent — what actually differs?
?
Durability, not speed. Scratch file systems are NOT replicated and data does not survive a file server failure — for temporary processing only. Persistent file systems replicate data and automatically replace failed file servers. If the data can't be re-created, it needs persistent (or a durable copy in S3).

Which FSx file system speaks both NFS and SMB?
?
FSx for NetApp ONTAP — which makes it the answer when Linux and Windows clients need access to the same data. FSx for OpenZFS speaks NFS and is built around cheap snapshots and clones.

Name the four Storage Gateway types and what each looks like locally.
?
S3 File Gateway — an NFS or SMB share, files land as S3 objects. FSx File Gateway — low-latency on-prem access to FSx for Windows File Server. Volume Gateway — an iSCSI disk. Tape Gateway — a physical tape library, so existing backup software keeps working against virtual tapes stored in AWS.

Volume Gateway: cached vs stored volumes — where does the PRIMARY copy live?
?
Cached: the primary data lives in S3, with a frequently-accessed subset kept locally. Chosen to stop on-premises storage growing. Stored: the ENTIRE dataset stays on premises, with asynchronous point-in-time snapshots to S3. Chosen when you need low-latency access to everything plus cheap offsite backups (recoverable to your data centre or to EC2).

DataSync vs Storage Gateway — what's the difference?
?
DataSync TRANSFERS data — a migration or a scheduled sync, then the job is done. Storage Gateway is a PERMANENT BRIDGE — the on-premises system keeps using it every day as if it were local storage. "Migrate 50 TB to S3" → DataSync. "Our backup software must keep writing to tape" → Tape Gateway.

What can DataSync move, and what does it add over a plain copy?
?
Sources: on-prem NFS, SMB, HDFS and object storage, plus other clouds. Destinations: S3, EFS, and all four FSx file systems. It adds automatic encryption in transit, DATA INTEGRITY VALIDATION on arrival, scheduling for recurring syncs, bandwidth control, and support for VPC endpoints so traffic never crosses the public internet.

When do you use the Snow Family instead of DataSync?
?
When the data volume is large enough that transferring over the network would take impractically long, or connectivity is poor. Snowball Edge ships physically — Storage Optimized 210 TB or Compute Optimized, encryption enforced, clusterable across 3–16 devices, and able to run EC2 and Lambda at the edge. Note: AWS states Snowball Edge is no longer available to NEW customers, directing them to DataSync, AWS Data Transfer Terminal, or Outposts.

What does AWS Backup give you that per-service backups don't?
?
One control plane. You write a backup plan (what, how often, retained how long), assign resources — often BY TAG — and backups land in a backup vault. Adds cross-Region copy, cross-account copy (requires AWS Organizations), lifecycle to cold storage, Backup Audit Manager for compliance evidence, and AWS Backup Vault Lock for WORM immutability.

What is AWS Backup Vault Lock?
?
WORM (write-once-read-many) enforcement on backups: nobody — including you — can delete a backup or shorten its retention period. Same shape as S3 Object Lock. It's the answer when a question requires backups that cannot be tampered with, even by an administrator.
