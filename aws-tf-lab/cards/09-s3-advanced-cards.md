---
topic: 09-s3-advanced
domain: performance
related_note: 09-s3-advanced
tags: [flashcards/s3]
---

# Cards for [[09-s3-advanced]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

CRR vs SRR — what's the difference and a use case for each?
?
Cross-Region Replication = destination bucket in a DIFFERENT region (DR, compliance distance, lower latency for far-away users). Same-Region Replication = destination in the SAME region (aggregate logs into one bucket, sync prod→test accounts, in-region data-sovereignty copies). Both are asynchronous and both support cross-account.

What are the requirements to enable S3 replication?
?
Versioning enabled on BOTH the source and destination buckets, plus an IAM role that S3 assumes (trust principal s3.amazonaws.com) with permission to read source object versions and write to the destination. Then a replication configuration on the source bucket.

Does S3 replication copy objects that already existed before you enabled it?
?
No — live replication (CRR/SRR) only copies objects created or updated AFTER the rule exists. To copy pre-existing objects (or ones that previously FAILED to replicate, or to a newly added destination) you run S3 BATCH REPLICATION, an on-demand job.

Is S3 replication transitive/chained?
?
No. If bucket A replicates to B, and B replicates to C, A's objects do NOT reach C. Replicas created by a replication rule can only be re-replicated using S3 Batch Replication.

Are delete markers replicated by default?
?
No — delete-marker replication is opt-in. That's usually what you want for a DR/backup copy: deleting in the source doesn't hide the object in the destination. Deleting a specific VERSION is never replicated.

What is S3 Replication Time Control (RTC)?
?
An SLA-backed replication option that replicates 99.99% of new objects within 15 minutes, with replication metrics in CloudWatch. It's the answer when a scenario demands predictable/compliance-driven replication time. It doesn't apply to Batch Replication.

At what sizes is multipart upload recommended and required?
?
AWS recommends multipart upload for objects 100 MB or larger. It's REQUIRED above 5 GB, because 5 GB is the maximum size of a single PUT. Max object size is 5 TB, using up to 10,000 parts.

Why use multipart upload?
?
Parts upload in PARALLEL (better throughput), and if a part fails you retry only that part instead of restarting the whole upload (resilience on flaky networks). You can also start uploading before you know the final object size, and pause/resume.

What hidden cost do incomplete multipart uploads create, and how do you fix it?
?
Uploaded parts are stored and BILLED until the upload is completed or aborted — and they don't show up in a normal object listing, so the cost is invisible. Find them with `aws s3api list-multipart-uploads`; prevent them with a lifecycle rule containing AbortIncompleteMultipartUpload (e.g. 7 days).

What is byte-range fetch used for?
?
Downloading only part of an object: read just a header/metadata without pulling the whole file, resume a broken download from where it stopped, or parallelize a large download by requesting several ranges at once. It's the download-side mirror of multipart upload.

What does S3 Transfer Acceleration actually do?
?
It changes the network PATH, not the data location. The client uploads to the nearest CloudFront EDGE LOCATION, and the data then travels to the bucket's region over AWS's private backbone instead of the public internet. The bucket stays in its region. Best for long-distance uploads of large objects; costs extra per GB.

What is S3 Select, and what's its current availability status?
?
SQL over a SINGLE object (CSV/JSON/Parquet) that returns only the matching subset, so less data crosses the wire — cheaper and faster than downloading the whole object. IMPORTANT: AWS states S3 Select is no longer available to NEW customers; existing users keep it. Modern answer for querying S3 with SQL is Amazon Athena (which queries many objects).

What are the four destinations for S3 Event Notifications?
?
SNS, SQS, Lambda, and EventBridge. EventBridge is the newer option with richer filtering, archive/replay and 20+ additional targets. Each destination needs a RESOURCE POLICY allowing s3.amazonaws.com to publish/invoke, or setup fails validation.

What's the classic infinite-loop mistake with S3 event notifications?
?
Having a Lambda triggered by ObjectCreated write its output back into the SAME bucket/prefix that triggers it — each write fires the event again, recursing forever and running up cost. Always write results to a different prefix or bucket, and use prefix/suffix filters on the rule.

What are the Glacier Flexible Retrieval restore times for Expedited, Standard and Bulk?
?
Expedited 1–5 minutes, Standard 3–5 hours, Bulk 5–12 hours (Bulk is free for Glacier Flexible Retrieval). For Glacier Deep Archive: Expedited is NOT available, Standard is ~12 hours and Bulk ~48 hours. Glacier Instant Retrieval needs no restore at all.

What is S3 Batch Operations?
?
A managed way to run a single action across millions of objects from a manifest — copy, tag, restore from Glacier, change ACLs, or invoke a Lambda per object — with retries and a completion report. It's what powers S3 Batch Replication.

Is replication a backup?
?
No — it's a copy. It doesn't protect against deletion (and if delete-marker replication is on, deletes propagate) or against corrupt data being replicated. Protection against deletion comes from versioning, Object Lock, and MFA delete.
