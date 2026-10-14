---
tags: [exam-prep, generated]
---

# 🎯 Signals — what the question says → what the answer is

> [!warning] Generated file — do not edit
> Built by `_scripts/build_signals.py` from `_data/signals.json`.
> Every row is checked against a verbatim quote in the note that owns it;
> an entry whose note stops supporting it is dropped and named below.

Your notes are organised by **service**. A question is organised by **what it
says**. This is the bridge: read the left column the way a stem reads, take the
middle column as the answer, and use the right column to kill the neighbour you
would otherwise pick.


## AI / ML  ·  7

**"train a custom model on our own data" / "our data science team" / "our own algorithm" — the ONLY wording that moves an ML question off a pre-trained service**  
→ **SageMaker** [[23-machine-learning#The two splits that actually get tested|23-machine-learning]]  
✗ A pre-trained API (Rekognition, Textract, Comprehend, Transcribe, Polly, Translate). Note the direction: "no ML expertise" / "fully managed" / "quickly add X" / "minimal development effort" appears in a huge share of ALL SAA stems and is NOT by itself a signal — it only tells you to stay on the pre-trained side, and the modality named in the stem then picks which one. Choosing SageMaker because it sounds more serious is the single most common ML wrong answer

**a call-centre stem that already uses Transcribe Call Analytics and wants speaker sentiment**  
→ **Call Analytics already produces speaker sentiment natively** [[23-machine-learning#Worked examples|23-machine-learning]]  
✗ Adding Comprehend — that is the over-built answer here, and is only required with plain Transcribe or Transcribe Medical

**employees ask natural-language questions of internal documents**  
→ **Amazon Kendra** [[23-machine-learning#Kendra vs OpenSearch|23-machine-learning]]  
✗ Comprehend (it analyses text for sentiment/entities/PII and returns no ranked results) and OpenSearch (a keyword index and log-dashboard engine you size and run)

**filter inappropriate or explicit user-uploaded images**  
→ **Rekognition content moderation — one API call** [[23-machine-learning#Worked examples|23-machine-learning]]  
✗ A SageMaker project to train an image classifier: it sounds like the serious answer and rebuilds a pre-trained feature

**multi-page PDFs or long audio processed from a Lambda**  
→ **The asynchronous job API plus an SNS completion notification** [[23-machine-learning#Traps|23-machine-learning]]  
✗ Calling the synchronous API — it handles single-page documents only, and Lambda's timeout kills the design on real input

**pull totals, fields or tables out of scanned invoices, forms or contracts**  
→ **Amazon Textract (AnalyzeExpense for invoices and receipts)** [[23-machine-learning#Traps|23-machine-learning]]  
✗ Rekognition — it reads scenes and text in a picture of the world, and does not preserve document structure or key-value pairs

**time-series demand or inventory prediction, with Amazon Forecast among the options**  
→ **Amazon Forecast is still the intended answer** [[23-machine-learning#Traps|23-machine-learning]]  
✗ Talking yourself out of it because the service is closed to new customers — it remains in the exam guide's in-scope list


## Compute  ·  11

**"a small number of critical instances that must not fail together" / "no correlated hardware failure"**  
→ **Spread placement group — distinct rack, network and power per instance** [[02-ec2#The three placement strategies|02-ec2]]  
✗ Partition placement group — it also isolates racks, but it is for large replicated clusters; Spread is capped at 7 running instances per AZ, so the fleet size in the stem is what picks between them

**"consistent low latency" / "sustained" high IOPS for a database**  
→ **io1 / io2 (io2 Block Express for the highest durability) — IOPS are provisioned, not earned** [[02-ec2#How `gp2` and `gp3` actually earn their IOPS|02-ec2]]  
✗ gp2 — credit-based and bursts only ~30 minutes, so it cannot hold the rate all day; HDD types are built for throughput, not latency

**"curl to 169.254.169.254 returns empty / 401 and the app has no credentials"**  
→ **IMDSv2: PUT to /latest/api/token first, then send the token in the X-aws-ec2-metadata-token header** [[02-ec2#Why a plain curl to the metadata endpoint returns nothing|02-ec2]]  
✗ "The instance profile didn't attach" — the usual conclusion, and usually wrong, because IMDSv2 fails silently rather than with a permissions verdict

**"occasionally used volume" with "peaks hitting a maximum of 3,000 IOPS"**  
→ **gp2 or gp3 — 3,000 is exactly gp2's burst ceiling and gp3's included baseline** [[02-ec2#How `gp2` and `gp3` actually earn their IOPS|02-ec2]]  
✗ io1/io2 Provisioned IOPS — buys nothing here; the words that would make it a Provisioned-IOPS question are "sustained" or "consistent", not "peak"

**"the data can be regenerated" + highest raw throughput + lowest cost**  
→ **Instance store (local NVMe)** [[02-ec2|02-ec2]]  
✗ io2 / "high provisioned IOPS" — the most expensive and most durable EBS type, so it loses "lowest cost" the moment the data is throwaway

**"the instance was terminated — what happened to the extra data volume that was attached at launch by the CLI / automation?"**  
→ **It was deleted — the launch-time DeleteOnTermination default for a data volume attached via CLI/API is Delete** [[02-ec2#Root volume vs data volume — the "Delete on termination" default|02-ec2]]  
✗ "Additional volumes always survive" — true for the console path only; the automated path defaults the other way, which is the whole point of the five-way table

**"we want to hibernate this existing server" (long warm-up, big in-memory cache)**  
→ **Launch a replacement instance with hibernation enabled, or migrate to one** [[02-ec2#Hibernate — the third way to switch an instance off|02-ec2]]  
✗ Changing a setting on the running instance — hibernation is a launch-time-only decision and cannot be switched on afterwards

**an on-premises system or internal DNS record is pinned to a private IP and must fail over to a standby instance**  
→ **Detach the secondary ENI from the failed instance and attach it to the standby — the private IP moves with it** [[02-ec2#Key facts, limits & pricing|02-ec2]]  
✗ Elastic IP — it maps a public address, and the pinned address here is private, so an EIP does not help at all

**one instance, no load balancer, and someone else’s firewall allowlist needs a fixed address**  
→ **Elastic IP associated with the instance** [[02-ec2#Why the public IP walks away when you stop|02-ec2]]  
✗ The auto-assigned public IPv4 — it belongs to the running instance, is released on stop and comes back different; note an EIP is billed hourly now either way

**the stem names Cassandra, HDFS, HBase or Kafka**  
→ **Partition placement group** [[02-ec2#The three placement strategies|02-ec2]]  
✗ Spread — it caps at 7 instances per AZ so it can never serve a big replicated cluster, however much the stem stresses isolation

**tightly coupled HPC AND the options are network adapters / placement strategies, and the stem names Windows or a t3/t3a type**  
→ **Plain ENA enhanced networking (free, on by default), inside a cluster placement group** [[02-ec2#Placement groups — telling EC2 where to put the instances relative to each other|02-ec2]]  
✗ EFA — the obvious pick for "HPC", but EFA's supported-OS table is Linux-only (Windows only for AWS CDI SDK apps) and burstable t-family is not on its supported instance list, so the HPC wording alone does not earn it


## Containers  ·  7

**"our ECS service can't keep up at peak"**  
→ **ECS Service Auto Scaling (Application Auto Scaling) on the service's desired task count** [[17-containers#Scaling ECS: the service and the capacity under it are two different things|17-containers]]  
✗ A scaling policy on the EC2 Auto Scaling group — different layer; it adds empty capacity and runs no more tasks, and on Fargate there is no instance layer at all

**"Pods must get addresses from these VPC subnets" / "Pods must reach VPC resources natively"**  
→ **The Amazon VPC CNI plugin** [[17-containers#Key facts, limits & pricing|17-containers]]  
✗ Transit Gateway, a VPN, or Kubernetes network policies — the last filters traffic rather than assigning addressing

**"the application in the container calls S3 / DynamoDB"**  
→ **Task role** [[17-containers#Task execution role vs task role|17-containers]]  
✗ Task execution role — that one is used by the ECS/Fargate agent (pull from ECR, awslogs, read secrets), and its credentials are not accessible to the containers

**EKS must handle a holiday traffic surge (and it is a Select-TWO)**  
→ **HPA plus the Metrics Server for pods, and Karpenter / Cluster Autoscaler / EKS Auto Mode for nodes** [[17-containers#Scaling EKS: two different layers, and a question usually needs both|17-containers]]  
✗ "Enable the HPA" alone — it adds pods, and once the nodes are full the extra pods stay Pending; "add nodes" alone leaves the deployment at its old replica count

**Fargate tasks behind an ALB — what target type does the target group use?**  
→ **ip** [[17-containers#⚠️ Traps — why the wrong answer looks right|17-containers]]  
✗ instance — with awsvpc each task has its own ENI and there is no EC2 instance ID to register, and Fargate always uses awsvpc

**give one Pod its own IAM permissions "without managing an OIDC provider", or use the same role across several clusters**  
→ **EKS Pod Identity (an association made through the EKS API, with the Pod Identity Agent DaemonSet)** [[17-containers#Giving a *Pod* an IAM role — IRSA vs EKS Pod Identity|17-containers]]  
✗ IRSA — also correct for per-Pod permissions, but it needs an OIDC provider per cluster and a separate trust-policy entry per cluster; attaching the role to the node group is wrong in shape, since every Pod on the node inherits it

**tasks moved to private subnets with the NAT gateway removed now fail with CannotPullContainerError, and the message mentions S3**  
→ **Add the free S3 gateway endpoint (alongside the ecr.api and ecr.dkr interface endpoints, and logs if using awslogs)** [[17-containers#Worked examples|17-containers]]  
✗ More ECR interface endpoints — the manifest already resolves; it is the image layers, which ECR stores in S3, that never download


## Cost  ·  8

**"existing server-bound licences" / per-socket or per-core BYOL**  
→ **Dedicated Hosts — you see sockets, cores and host affinity** [[13-cost-optimization#When each purchasing option is the answer|13-cost-optimization]]  
✗ Dedicated Instances — also single-tenant, but no host-level visibility, which is exactly what per-socket/per-core licensing needs

**"must be certain an instance can be launched in a specific Availability Zone" (DR standby, licensed capacity)**  
→ **On-Demand Capacity Reservation, or a zonal Reserved Instance** [[13-cost-optimization#When each purchasing option is the answer|13-cost-optimization]]  
✗ Buying a Savings Plan — it is purely a billing discount and never reserves capacity; a regional RI does not hold capacity either

**"notify us before we exceed $5,000"**  
→ **AWS Budgets** [[13-cost-optimization#Traps|13-cost-optimization]]  
✗ Cost Explorer — it analyses and forecasts the past/future but does not alert; Cost Anomaly Detection alerts on unusual spend rather than a figure you name

**"they know exactly what they will run for the next three years" and want the deepest committed discount**  
→ **EC2 Instance Savings Plan (up to 72%), committed to one family in one Region** [[13-cost-optimization#When each purchasing option is the answer|13-cost-optimization]]  
✗ Compute Savings Plan — more flexible and therefore cheaper a discount (66%); the counterintuitive direction is the whole question

**"we may need to switch instance families later" but still want a reservation**  
→ **Convertible RI — it can be exchanged for another Convertible RI with different attributes** [[13-cost-optimization#Traps|13-cost-optimization]]  
✗ Standard RI — the bigger discount, and it can be modified but never exchanged, so it fails the requirement however good the rate looks

**Spot instances configured with the hibernate interruption behaviour — how much warning do you get?**  
→ **An interruption notice, but not two minutes of lead time — hibernation begins immediately** [[13-cost-optimization#Traps|13-cost-optimization]]  
✗ The usual "two-minute notice" rule, which holds only for the stop and terminate behaviours

**steady baseline compute spend, but they keep migrating between instance families and are moving work to Fargate/Lambda**  
→ **Compute Savings Plan (up to 66%) — flexible across family, size, Region, OS, tenancy, and covers Fargate and Lambda** [[13-cost-optimization#When each purchasing option is the answer|13-cost-optimization]]  
✗ EC2 Instance Savings Plan or a Reserved Instance — the deeper discount, but locked to one family (and one Region), so it is wasted the moment they migrate

**the stem wants a specific recommended instance type or size for ONE named workload, from observed utilisation — "right-size", "what should this instance be"**  
→ **AWS Compute Optimizer (rightsizing recommendations from CloudWatch metrics)** [[13-cost-optimization#Key facts, limits & pricing|13-cost-optimization]]  
✗ Cost Explorer’s own rightsizing recommendations (a SPEND view that nets out what you already own) and Trusted Advisor low-utilization checks — both look right and neither returns a named replacement type. Scaling out answers availability, not sizing


## DNS & edge  ·  18

**a CloudFront distribution is already in the architecture and named countries must be DENIED the content (403)**  
→ **CloudFront geo restriction (allow/block list, applied to the whole distribution, 403 to blocked viewers)** [[11-cloudfront#Traps|11-cloudfront]]  
✗ Route 53 geolocation routing — it chooses which endpoint a country is sent to, not whether it may access the content

**a failover record that is an alias to an ALB**  
→ **Set Evaluate Target Health = Yes on the alias and attach no health check** [[10-route53#Traps|10-route53]]  
✗ Attaching your own health check to the record — that is only for raw IPs and non-AWS endpoints

**a globally fast static site where the S3 bucket must stay completely private**  
→ **OAC on an S3 REST-endpoint origin, plus a bucket policy granting s3:GetObject to cloudfront.amazonaws.com conditioned on AWS:SourceArn = your distribution's ARN** [[11-cloudfront#Worked examples|11-cloudfront]]  
✗ The same policy without the condition: everything works, but the service principal is identical for every AWS customer, so any distribution could read the bucket. OAI is the legacy variant

**a valid ACM certificate never appears in the distribution's certificate list**  
→ **Request or import the viewer-facing certificate in us-east-1** [[11-cloudfront#Traps|11-cloudfront]]  
✗ Issuing it in the origin's or your own Region — only the CloudFront→origin leg with an ELB origin may use any Region

**automatic origin failover for an API or a write path (POST/PUT)**  
→ **Not an origin group — failover happens only for GET, HEAD and OPTIONS viewer requests** [[11-cloudfront#Traps|11-cloudfront]]  
✗ CloudFront origin groups, which read as the obvious in-CloudFront failover answer

**CloudFront in front of an S3 bucket configured as a static website endpoint, with the bucket required to be private**  
→ **Switch the origin to the S3 REST endpoint and use OAC, replacing S3's website features with CloudFront's default root object and custom error pages** [[11-cloudfront#Traps|11-cloudfront]]  
✗ OAC (or OAI) on the website endpoint — a website endpoint is a custom origin and supports neither

**each country must be SERVED A DIFFERENT endpoint or site**  
→ **Geolocation routing — plus a * default record so unmatched locations get an answer** [[10-route53#Traps|10-route53]]  
✗ Geoproximity — it reads where your resources are and offers a bias dial, not where the user is

**edge logic must call another AWS service, use the SDK, or inspect the request body**  
→ **Lambda@Edge** [[11-cloudfront#Traps|11-cloudfront]]  
✗ CloudFront Functions — no network access, no request body, viewer events only, 10 KB of code (and it is the right answer for a plain header or URL rewrite at huge scale)

**failover record shows healthy in the console, but users kept reaching the dead site for an hour**  
→ **The record's TTL — lower it (~60s) on failover-critical records** [[10-route53#Traps|10-route53]]  
✗ Shortening the health check interval or failure threshold: Route 53's own half is ~90s, and the TTL term dominates it

**hand clients several IP addresses but stop handing out the ones that are down**  
→ **Multivalue answer routing — up to 8 healthy records, randomly ordered** [[10-route53#Traps|10-route53]]  
✗ Simple routing: it returns all values in random order with no health checking at all, so a dead server keeps being served. Weighted if the stem wants fixed proportions; an ALB if it wants real load balancing

**health check a resource that has no public address (an instance in a private subnet)**  
→ **Health check the public-facing load balancer instead, or use a CloudWatch alarm health check driven by a metric the private resource publishes** [[10-route53#Traps|10-route53]]  
✗ An endpoint health check pointed at the private IP — Route 53's checkers live on the public internet

**on-premises DNS servers must resolve names held in AWS (private hosted zones, VPC names)**  
→ **A Route 53 Resolver inbound endpoint** [[10-route53#Traps|10-route53]]  
✗ Outbound endpoint — that is for your VPC resolving on-premises names; anchor on the direction the query travels, not the answer

**public hosted zone created and the records look right, but the name resolves for nobody on the internet**  
→ **Point the domain's registrar at the zone's four assigned name servers — the missing NS delegation** [[10-route53#Traps|10-route53]]  
✗ Editing records, lowering TTLs or adding health checks: that treats a delegation problem as a zone problem

**shift more traffic toward the bigger/closer data centre and tune the share between sites**  
→ **Geoproximity routing with a bias value (+1…+99 expands, −1…−99 shrinks)** [[10-route53#Traps|10-route53]]  
✗ Geolocation — it maps user locations to records and has no dial for shifting traffic volume

**static ANYCAST IPs fronting endpoints in two or more Regions, or non-HTTP (UDP / gaming / VoIP), or failover that must not wait for DNS caches**  
→ **AWS Global Accelerator — two static anycast IPs, TCP/UDP, caches nothing** [[11-cloudfront#Traps|11-cloudfront]]  
✗ CloudFront: it caches HTTP at the edge and is reached by DNS name, so a failover still waits for resolver caches to expire

**temporary access to private content served THROUGH A CLOUDFRONT DISTRIBUTION**  
→ **CloudFront signed cookies** [[11-cloudfront#Signed URLs vs signed cookies (private content)|11-cloudfront]]  
✗ Signed URLs — one file each, and they change the URLs

**the root/apex domain (example.com, no www) must point at an ALB or CloudFront**  
→ **A Route 53 alias record (it resolves as A/AAAA, so the apex rule is never violated)** [[10-route53#Traps|10-route53]]  
✗ CNAME — DNS forbids a CNAME coexisting with the SOA and NS records the apex must carry, so it is illegal there rather than merely unsupported by AWS

**viewers get 502 Bad Gateway from CloudFront**  
→ **No domain in the origin's certificate matches the origin domain name** [[11-cloudfront#Key facts, limits & pricing|11-cloudfront]]  
✗ Treating it as a viewer-certificate or cache problem


## Databases  ·  26

**"a full-size, isolated copy of production for staging, in minutes, at almost no extra storage cost" (Aurora)**  
→ **Aurora cloning (copy-on-write, up to 15 clones)** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ A snapshot restore physically copies every byte; Backtrack rewinds the source cluster instead of giving you a second one.

**"a single-instance Aurora cluster took ~10 minutes to recover" / "why was the failover so slow?"**  
→ **Add a reader instance in another AZ — with no reader there is nothing to promote, so Aurora must create a new primary** [[07-rds-aurora#Worked examples|07-rds-aurora]]  
✗ "Aurora isn't Multi-AZ, so redeploy on RDS Multi-AZ" — AWS applies the Multi-AZ term to Aurora directly; the real difference is that Aurora's second-AZ instance is a reader that doubles as the failover target.

**"about 15 minutes after each deploy, NEW database connections fail while existing connections keep working"**  
→ **The IAM auth token was minted once at startup and cached as the password — generate it inside the connection factory** [[07-rds-aurora#Worked examples|07-rds-aurora]]  
✗ "The database is failing over" or "max_connections exhausted" — those break existing connections too; the giveaway is that open sessions are unaffected.

**"an existing, running, unencrypted database must now be encrypted at rest"**  
→ **Snapshot → copy the snapshot with encryption enabled → restore the copy (new instance, new endpoint)** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ "Modify the DB instance and enable encryption" — encryption at rest is a creation-time-only property, so that option does not exist.

**"cross-Region DR / local reads in other Regions for an Aurora PostgreSQL cluster"**  
→ **Aurora Global Database (1 primary + up to 10 read-only Regions, sub-second replication)** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ A cross-Region Aurora Replica — that binlog-based option exists on Aurora MySQL only; Aurora PostgreSQL does not support it.

**"database users must sign in with their existing corporate / Active Directory credentials" / "single sign-on to the database"**  
→ **Kerberos authentication with AWS Managed Microsoft AD** [[07-rds-aurora#07 – RDS & Aurora|07-rds-aurora]]  
✗ IAM database authentication (that is a signed token, not corporate SSO) and Secrets Manager (that is still password auth). Also note Kerberos is unsupported on MariaDB, so a MariaDB stem is not this.

**"friends-of-friends" / "fraud rings" / "queries that walk many relationships / multiple hops"**  
→ **Amazon Neptune (graph database)** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ Aurora — in SQL each hop is another join, so the query degrades as hops grow; Redshift is columnar analytics and OpenSearch is text search.

**"live top-100 leaderboard / ranking / real-time counter"**  
→ **Redis sorted sets** [[08-elasticache#Worked examples|08-elasticache]]  
✗ Memcached (simple key-value only) and a relational ORDER BY score over millions of rows per request.

**"microsecond reads for DynamoDB with no application rewrite"**  
→ **DynamoDB Accelerator (DAX) — API-compatible, swap the client** [[08-elasticache#DAX — the cache that only fronts DynamoDB|08-elasticache]]  
✗ ElastiCache — it can cache anything but you would write your own cache-aside logic; it cannot front DynamoDB as a drop-in. Reverse the database and ElastiCache wins, since DAX cannot front a relational database at all.

**"migrate SQL Server to Aurora PostgreSQL with minimal application code changes" with Babelfish and SCT+DMS both listed as options**  
→ **Both — Babelfish for the application's T-SQL/driver, SCT + DMS for schema and data (a Select TWO)** [[07-rds-aurora#Worked examples|07-rds-aurora]]  
✗ Picking just one: Babelfish alone leaves an empty database; SCT+DMS alone leaves every query to be rewritten. Also eliminate Glue "converting T-SQL" and a custom endpoint "emulating SQL Server".

**"move our MongoDB application to AWS with no application code change"**  
→ **Amazon DocumentDB (MongoDB-compatible)** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ DynamoDB — its API forces an application rewrite, so it fails the "no code change" requirement.

**"multi-threaded cache that can use all cores of a large node"**  
→ **Memcached** [[08-elasticache#Redis is single-threaded — and that is not a bug|08-elasticache]]  
✗ Redis — command execution is single-threaded (one core per node); it buys throughput with cluster-mode shards, not bigger boxes. This one gets remembered backwards.

**"must remain available if an entire Availability Zone fails" / "no data loss on failover"**  
→ **RDS Multi-AZ (synchronous standby, automatic DNS failover)** [[07-rds-aurora#Multi-AZ and read replicas are two different jobs|07-rds-aurora]]  
✗ A read replica — it is asynchronous and promotion is manual, so it is read scaling, not HA.

**"offload reporting/BI queries off production at the lowest cost"**  
→ **A same-Region read replica (in another AZ) — replication traffic is free** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ A cross-Region replica: that one is billed as inter-Region transfer, and is only right when the requirement is DR or readers in another geography. A same-AZ replica buys nothing either — the cross-AZ charge does not apply to replication.

**"our Aurora bill is dominated by I/O charges" / "I/O is a quarter or more of Aurora spend"**  
→ **Switch the cluster to Aurora I/O-Optimized** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ Aurora Standard — it bills per million I/O requests and only wins below the ~25% threshold. Note you can move to I/O-Optimized only once every 30 days.

**"remove hard-coded database credentials" / "the application should authenticate using its IAM role, with no password stored"**  
→ **Enable IAM database authentication (then rds-db:connect on the dbuser ARN)** [[07-rds-aurora#Worked examples|07-rds-aurora]]  
✗ "Attach an IAM role to the instance" or "restrict the security group to the app tier" offered on their own — a role is an identity control and an SG is a network control; neither authenticates to the engine, and the feature is off by default.

**"see how individual processes or threads on the DB instance are using CPU and memory"**  
→ **Enhanced Monitoring (agent inside the instance → CloudWatch Logs, RDSOSMetrics)** [[07-rds-aurora#The three RDS monitoring layers (the one the exam confuses)|07-rds-aurora]]  
✗ Standard CloudWatch metrics — CPUUtilization, FreeableMemory, DatabaseConnections are hypervisor-level and available with Enhanced Monitoring off; they describe the instance, not a process. Performance Insights answers "which query", not "which process".

**"strongly consistent reads are required" in a question that also offers a cache**  
→ **DAX does not help — a strongly consistent read passes straight through** [[08-elasticache#DAX — the cache that only fronts DynamoDB|08-elasticache]]  
✗ Picking DAX on the strength of "microseconds" alone; consistency is the second discriminator and it eliminates DAX whatever else fits. DAX is also wrong for write-heavy workloads.

**"the client must discover all cache nodes automatically as nodes are added or removed" / "node discovery"**  
→ **Memcached with Auto Discovery (plus an ElastiCache client library that supports it)** [[08-elasticache#Key facts, limits & pricing|08-elasticache]]  
✗ Redis/Valkey — AWS states Auto Discovery is not available for them, so there is no Redis equivalent to muddy this signal. It outranks a Redis-sounding use case in the same stem.

**"the Redis cluster must fail over automatically" (and the stem describes a single node)**  
→ **Multi-AZ needs at least one replica — minimum 2 nodes; a single-node cluster cannot fail over** [[08-elasticache#Key facts, limits & pricing|08-elasticache]]  
✗ Assuming "Redis = HA" from the engine alone; the replica is what makes failover possible, and on cluster mode enabled automatic failover is required rather than optional.

**"thousands of concurrent Lambda executions exhaust the database's connections"**  
→ **RDS Proxy** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ Adding read replicas or a bigger instance class — more capacity does not stop each concurrent execution from opening its own connection.

**"unpredictable / intermittent / variable workload" + "minimize cost" on a relational database**  
→ **Aurora Serverless v2** [[07-rds-aurora#Worked examples|07-rds-aurora]]  
✗ A right-sized provisioned instance (idle hours still bill) — and plain RDS has no true serverless mode.

**"upgrade the database engine version with minimal downtime"**  
→ **Blue/green deployment** [[07-rds-aurora#Key facts, limits & pricing|07-rds-aurora]]  
✗ Multi-AZ — it protects against failure, not a planned engine upgrade; both primary and standby get upgraded.

**"user sessions must survive a cache node failure" / "data loss on node failure is unacceptable"**  
→ **Redis/Valkey (replication group, Multi-AZ auto-failover, persistence, backup)** [[08-elasticache#What Memcached simply does not have|08-elasticache]]  
✗ Node-based Memcached — no replication, failover, persistence or backup, so a node loss loses the data. Scope it: if the stem names Serverless Memcached, do not eliminate it for lacking durability.

**the options are architectural ("add ElastiCache in front of the DB") and the bottleneck is writes, or a strongly consistent read is required**  
→ **A cache is the wrong tool — it accelerates reads only** [[08-elasticache#Worked examples|08-elasticache]]  
✗ "Add ElastiCache in front of the database" offered as the performance fix; lazy loading would happily serve a stale answer.

**the stem has already decided to cache and the options are caching STRATEGIES (lazy loading / TTL / write-through) — "must never serve stale data"**  
→ **Write-through (write to cache and DB on every write)** [[08-elasticache#Caching strategies|08-elasticache]]  
✗ Lazy loading plus TTL — TTL only bounds staleness, it does not remove it. The cost of write-through is slower writes and caching data nobody reads.


## Decoupling  ·  9

**an existing application already speaking OpenWire, STOMP or AMQP to a broker, and its messaging code must not be rewritten**  
→ **Amazon MQ** [[15-decoupling#Key facts, limits & pricing|15-decoupling]]  
✗ SQS/SNS, which speak only the AWS API so adoption means a rewrite — and note that MQTT telemetry from constrained devices points at IoT Core, not MQ

**an S3 event notification must end up in a FIFO queue**  
→ **Put EventBridge in the middle — S3 cannot name a FIFO queue (or an SNS FIFO topic) as an event-notification destination** [[15-decoupling#Key facts, limits & pricing|15-decoupling]]  
✗ Configuring the FIFO queue directly as the S3 event destination

**empty receives while messages are waiting, wasted API calls, polling cost**  
→ **Long polling — WaitTimeSeconds up to 20 seconds** [[15-decoupling#Traps|15-decoupling]]  
✗ Assuming an empty response means an empty queue: short polling is the default and samples only a subset of SQS servers

**ingest events natively from a third-party SaaS provider**  
→ **EventBridge — partner event sources and custom event buses** [[15-decoupling#Key facts, limits & pricing|15-decoupling]]  
✗ SNS: it can push notifications out to third-party providers but cannot ingest a SaaS partner's events; the direction is the discriminator

**one event, several independent consumers, each needing a durable buffer — no replay or ordering asked for; the stated risk is a subscriber being DOWN at delivery time**  
→ **SNS topic fanning out into one SQS queue per consumer** [[15-decoupling#Traps|15-decoupling]]  
✗ SNS delivering straight to Lambda or an HTTP endpoint — SNS delivers, it does not hold, so a down subscriber loses the notification

**one message keeps failing and consumers are stuck looping on it**  
→ **A dead-letter queue via a redrive policy with maxReceiveCount — and give the DLQ longer retention than the source** [[15-decoupling#Traps|15-decoupling]]  
✗ Raising the retention period or adding consumers; neither puts an upper bound on retries

**scale a queue-consumer fleet to meet a stated latency SLA ("process within N seconds")**  
→ **Target-track on ApproximateAgeOfOldestMessage** [[15-decoupling#Scaling the consumers on the queue itself|15-decoupling]]  
✗ Backlog per instance (right for keeping up with throughput, not for a latency SLA) and consumer CPU (an I/O-blocked consumer shows no CPU while the backlog grows)

**the same job was processed twice, nothing errored, logs look normal**  
→ **The visibility timeout is shorter than the processing time — raise it (or extend the lease with ChangeMessageVisibility) and make the consumer idempotent** [[15-decoupling#Traps|15-decoupling]]  
✗ A duplicate publish, or switching to FIFO: the cause is that receiving hides a message rather than deleting it

**three broker nodes behind a Network Load Balancer across Availability Zones**  
→ **Amazon MQ for RabbitMQ, cluster deployment (each node on its own EBS volume)** [[15-decoupling#Traps|15-decoupling]]  
✗ ActiveMQ active/standby — that is two brokers in two AZs on shared EFS; RabbitMQ has no active/standby mode and no EFS option


## Identity & access  ·  34

**"prevent resources from being created unless the cost-centre tag is supplied"**  
→ **An SCP (or IAM policy) using aws:RequestTag/x and aws:TagKeys** [[01-iam-advanced#Key facts, limits & pricing|01-iam-advanced]]  
✗ A tag policy (standardises and reports, needs enforcement turned on per resource type) or Config required-tags (detects after the fact and does not prevent creation)

**"a third-party vendor that serves many customers needs access to our account" / confused-deputy wording**  
→ **Cross-account role whose trust policy carries a sts:ExternalId condition, with the ExternalId generated by the vendor** [[01-iam#Worked examples|01-iam]]  
✗ "Keep the ExternalId secret" / "make it unguessable" — it is not a secret; its job is to be unique per customer so the vendor cannot be tricked into using account A's role for customer B

**"a user was created with the CLI/API and cannot make any API calls"**  
→ **Expected — a programmatically created user has no password and no access keys; create credentials (or use a role instead)** [[01-iam#Key facts, limits & pricing|01-iam]]  
✗ Assuming a missing permissions policy is the cause — only the console create-user flow offers to generate credentials

**"allow every account in our organization to use this bucket/key without listing account IDs, and without updating the policy as accounts are added"**  
→ **aws:PrincipalOrgID condition in the resource policy** [[01-iam-advanced#Condition keys worth memorising|01-iam-advanced]]  
✗ Enumerating account ARNs as principals, or an SCP — the SCP cannot grant the access at all

**"bring our existing AWS accounts under one organization"**  
→ **Invite each account from the management account; its owner accepts (invitations expire after 15 days)** [[01-iam-advanced#Which multi-account requirement does this solve?|01-iam-advanced]]  
✗ "Create" the accounts — you only create brand-new ones; and an account belongs to one organization at a time, so moving one means removing it first

**"central IT cannot assume into the accounts we invited, although it works for the ones Organizations created"**  
→ **OrganizationAccountAccessRole is created automatically only for accounts Organizations creates — add it yourself in invited accounts** [[01-iam-advanced#Which multi-account requirement does this solve?|01-iam-advanced]]  
✗ Blaming the SCPs or the trust policy wording when the role simply does not exist

**"enforce password length, complexity and mandatory rotation for all IAM users"**  
→ **Set the account password policy (one per account)** [[01-iam#Key facts, limits & pricing|01-iam]]  
✗ An IAM policy you attach, a per-user setting, or an AWS Config rule — none of those is where the password policy lives

**"find which resources are shared with an external entity" / "identify roles, keys and permissions nobody has used" / "generate a least-privilege policy from past activity"**  
→ **IAM Access Analyzer (external access, unused access, policy validation, policy generation)** [[01-iam#Key facts, limits & pricing|01-iam]]  
✗ AWS Config or Trusted Advisor — they check resource configuration, not who can actually reach what through policy

**"let the junior admin create users but never an administrator" — one account, delegated administration**  
→ **A permissions boundary, with iam:PermissionsBoundary as a condition on iam:CreateUser** [[01-iam-advanced|01-iam-advanced]]  
✗ An SCP — it needs Organizations and caps the whole account, not one identity; use it for "prevent anyone in the org"

**"on-premises servers / VMs outside AWS need temporary AWS credentials with no access key baked in"**  
→ **IAM Roles Anywhere — X.509 certificate from your CA → trust anchor → role → profile** [[01-iam-advanced#IAM Roles Anywhere — IAM roles for machines that are not in AWS|01-iam-advanced]]  
✗ An IAM user with a long-lived access key (the thing Roles Anywhere replaces), and IAM Identity Center (a human signing in, not a machine)

**"only these instance types may be launched, across every account, with the least effort"**  
→ **An SCP Deny attached at the OU** [[01-iam-advanced#RAM shares resources; it never enforces policy|01-iam-advanced]]  
✗ AWS RAM — the word "multi-account" pulls toward it, but RAM permissions are Allow-only and can never express a prohibition

**"our CI/CD pipeline (GitHub Actions) needs AWS credentials with nothing stored in CI secrets"**  
→ **Register the OIDC provider in IAM and create a role trusted for sts:AssumeRoleWithWebIdentity, conditioned on the token's sub claim** [[01-iam#Worked examples|01-iam]]  
✗ Storing an IAM user's access key in CI secrets — long-lived and unrotated; also distinct from IAM Roles Anywhere, which is for X.509-authenticated machines outside AWS

**"our identity store is not compatible with SAML 2.0"**  
→ **Build a custom identity broker that authenticates locally and calls STS (AssumeRole or GetFederationToken)** [[01-iam-advanced#When the identity store is not SAML-compatible|01-iam-advanced]]  
✗ IAM Identity Center — it needs a supported identity source (Managed AD, AD Connector, an external SAML IdP or its own store); a raw LDAP store is not one. This one phrase is the documented exception to "write a custom application is always wrong"

**"permissions must scale as teams are added" / "avoid policy sprawl" / "access based on project or cost-centre tags"**  
→ **ABAC — aws:PrincipalTag/x compared against aws:ResourceTag/x** [[01-iam-advanced#RBAC vs ABAC|01-iam-advanced]]  
✗ RBAC: a new role plus a new policy per team is exactly the sprawl the stem is complaining about

**"rotate the RDS/Aurora master user password automatically with the least operational overhead / without maintaining a Lambda"**  
→ **Secrets Manager managed rotation** [[01-iam#How an application authenticates to RDS|01-iam]]  
✗ A Secrets Manager Lambda rotation function — that is the pattern for ordinary application credentials, and writing one is extra overhead the managed path removes

**"share the VPC subnets / the transit gateway with the other accounts in the organization"**  
→ **AWS RAM** [[01-iam-advanced#RAM shares resources; it never enforces policy|01-iam-advanced]]  
✗ Do not reflexively eliminate RAM on governance-flavoured multi-account stems — sharing a concrete resource (subnets, transit gateway, Resolver rules, License Manager configs) is exactly its job

**"stand up a compliant multi-account environment quickly" / "vend new pre-configured accounts" / "following best practices"**  
→ **AWS Control Tower (landing zone, Account Factory, controls)** [[01-iam-advanced|01-iam-advanced]]  
✗ Organizations + hand-written SCPs — Organizations is the primitive; "apply one specific permission guardrail" is the SCP question, not this one

**"standardise the case and allowed values of tag keys across the OU and report what is non-compliant"**  
→ **An Organizations tag policy** [[01-iam-advanced#Key facts, limits & pricing|01-iam-advanced]]  
✗ Expecting it to require a tag — untagged resources are not even evaluated, so a tag policy can never force a tag to exist

**"stop principals from outside our organization from reaching our S3 buckets / our resources"**  
→ **A resource control policy (RCP) at the root/OU/account** [[01-iam#Key facts, limits & pricing|01-iam]]  
✗ An SCP — an SCP caps your own principals in member accounts; it does nothing about external callers

**"the account admin holds AdministratorAccess and still gets AccessDenied" / "attach an SCP so the developers can use S3"**  
→ **SCPs only cap; effective permission is the intersection, so an IAM policy must grant it too** [[01-iam-advanced#Key facts, limits & pricing|01-iam-advanced]]  
✗ Any option phrased "use an SCP to grant / enable / allow" — an SCP's Allow means "not forbidden here", never "you may"

**"the bucket policy in account A allows the role in account B, but the call is still denied"**  
→ **Cross-account requests are evaluated twice — the caller's identity policy and the resource policy must both allow** [[01-iam-advanced#How policy types combine|01-iam-advanced]]  
✗ The identity-plus-resource union rule, which holds only inside a single account

**"the IP-allowlist policy worked until we moved the traffic onto a VPC endpoint, now everything is denied"**  
→ **aws:SourceIp is absent for requests through a VPC endpoint — use aws:VpcSourceIp, aws:SourceVpc or aws:SourceVpce** [[01-iam#Reading a policy document in twenty seconds|01-iam]]  
✗ "Add the instance's private IP to the allowlist" — aws:SourceIp only ever matches public ranges, so a private address never matches either

**"the MFA-required policy is not blocking CLI calls made with access keys" (or is blocking them when it should not)**  
→ **Use BoolIfExists — aws:MultiFactorAuthPresent is absent, not false, for long-term access keys** [[01-iam-advanced|01-iam-advanced]]  
✗ Plain Bool, which misfires in both directions depending on whether the statement is a Deny or an Allow

**"the role exists and its permissions are correct, but the EC2 instance still gets AccessDenied / no credentials"**  
→ **The instance profile is missing or unreferenced — EC2 receives a role only through an instance profile** [[01-iam#The instance profile — the wrapper the console hides|01-iam]]  
✗ "Attach the role directly to the instance" — Lambda and ECS take a role directly, EC2 is the odd one, and the console hides the wrapper so it looks like a non-issue

**"the SCP does not restrict this account's root user / its administrators at all"**  
→ **It is the management account — entirely exempt from SCPs, which is why you keep no workloads there** [[01-iam-advanced|01-iam-advanced]]  
✗ Assuming the same exemption for a member account's root user — that one is capped; the asymmetry is the tested point

**"the session must last 8 hours but we assume one role from another role" (role chaining)**  
→ **Capped at 1 hour regardless of the role's max session duration** [[01-iam#User vs Role|01-iam]]  
✗ Answering "12 hours" from the normal max-session-duration rule — chaining overrides it

**"use existing corporate credentials / no new IAM users" AND the options are about HOW ACCESS IS GRANTED (IAM users vs federation, groups vs permission sets)**  
→ **Federate: directory → IAM Identity Center → AD group mapped to a permission set → IAM role** [[01-iam|01-iam]]  
✗ "Create an IAM user for each employee" — it duplicates the identity source, so there are then two places to deprovision a leaver, which is the failure the stem is built on

**"we attached an SCP that denies one service and now everything in that OU fails"**  
→ **FullAWSAccess was detached — SCP evaluation needs an explicit Allow at every level, and a Deny-only policy leaves the level's permitted set empty** [[01-iam-advanced#Key facts, limits & pricing|01-iam-advanced]]  
✗ Looking for a fault in the Deny statement itself; the Deny is fine, the missing Allow is the cause

**"which of these still requires the root user?" where one option is changing the account name**  
→ **Account name is not root-only (nor are contact info, alternate contacts, payment currency, Regions); root is needed for the email, password and access keys, closing a standalone account, restoring locked-out IAM permissions, removing an all-deny bucket/SQS policy, and activating IAM access to Billing** [[01-iam#Key facts, limits & pricing|01-iam]]  
✗ Treating every "account setting" as root-only — and note the standalone-vs-member discriminator: in an Organization the management account can do several of these for member accounts

**a federation answer offers to put the federated/AD users into an IAM group**  
→ **Distractor — an IAM group contains only IAM users and is never a Principal; the AD group maps to an IAM role** [[01-iam|01-iam]]  
✗ The word "group" appearing in both the AD and IAM senses; only the AD one is the unit of assignment

**an option offers to encrypt the root access keys and store them in S3, email them, or share them only with the owner**  
→ **Wrong by construction — root access keys should not exist at all** [[01-iam#Key facts, limits & pricing|01-iam]]  
✗ Careful-sounding key handling; the strength of the storage story is irrelevant because the key should not be created

**database stem stresses that users must authenticate with their existing Active Directory accounts (rather than "no stored password")**  
→ **RDS Kerberos / Microsoft AD authentication, not IAM DB auth** [[01-iam|01-iam]]  
✗ IAM database authentication — it is the answer to "no stored password", not to "reuse the existing AD identities"; for PostgreSQL the two cannot both be enabled

**group policy Allows an action, an inline policy on the user Denies it — "can she do it?" (or "the Allow was attached first" / "the inline policy is more specific")**  
→ **Denied. One explicit Deny anywhere wins; order, count and specificity are irrelevant** [[01-iam#Explicit Deny wins, and nothing else counts|01-iam]]  
✗ "The more specific policy wins" — that rule exists in NTFS ACLs, which is exactly why it sounds right; IAM has no specificity rule

**policy JSON shown; the user can read objects but ListBucket fails (or vice versa)**  
→ **The /* is in the wrong place — bucket-level actions need the bare bucket ARN, object actions need bucket/*** [[01-iam#Reading a policy document in twenty seconds|01-iam]]  
✗ Reading bucket* as "the bucket and its objects" — it is a prefix match on bucket names, and the mismatch fails silently


## Load balancing & scaling  ·  11

**"a single instance that cannot be load balanced must survive an AZ outage, at the lowest cost"**  
→ **An Auto Scaling group with min = max = desired = 1 spanning two or more AZs** [[04-alb-asg#Key facts, limits & pricing|04-alb-asg]]  
✗ A second standby instance, or adding an ALB — neither is needed and both cost more; nothing scales here, the group just relaunches the instance in the surviving AZ

**"guarantee capacity is warm for a known 09:00 rush" while traffic for the rest of the day stays unpredictable**  
→ **A scheduled action that sets only desired capacity, leaving min/max alone, plus the existing dynamic policy** [[04-alb-asg#Worked examples|04-alb-asg]]  
✗ Pinning min = max at the scheduled number — that answers "run exactly N at 9am" and switches dynamic scaling off for the day

**"must still serve N instances' worth of traffic with one Availability Zone gone"**  
→ **per-AZ = N ÷ (A − 1), and set minimum capacity to A × that (N=2 over 2 AZs ⇒ minimum 4)** [[04-alb-asg#Sizing for AZ loss — required capacity × AZ count|04-alb-asg]]  
✗ Minimum capacity = N — the right total with no spare zone; and "one instance per AZ across N AZs", which gets the total right and the per-AZ wrong

**"patch / troubleshoot one instance in the group without the group replacing it"**  
→ **Put it in Standby (simplest for one instance), or suspend ReplaceUnhealthy and HealthCheck** [[04-alb-asg#Key facts, limits & pricing|04-alb-asg]]  
✗ Suspending ScheduledActions — the process everyone has heard of, but it only pauses scheduled scaling and does nothing about replacement

**"redirect all HTTP traffic to HTTPS with no application changes"**  
→ **An ALB listener rule on :80 with a redirect action to HTTPS:443, HTTP_301** [[04-alb-asg#Worked examples|04-alb-asg]]  
✗ CloudFront, a Lambda, a second load balancer, or an instance-level rewrite — and an NLB, which is Layer 4 and cannot rewrite HTTP at all (HTTPS→HTTP is never allowed either)

**"several unrelated domain names must be served by one load balancer, each with its own certificate"**  
→ **Attach a certificate list to the one HTTPS listener — SNI selects per hostname, at no extra charge** [[04-alb-asg#Key facts, limits & pricing|04-alb-asg]]  
✗ A wildcard certificate (covers one domain's subdomains, one level only), a SAN re-issue, or a new CloudFront distribution

**"which instance does the group terminate when it scales in?"**  
→ **The AZ with the most instances is chosen first, then within it the oldest configuration (launch configuration → different launch template → oldest version)** [[04-alb-asg#Which instance dies when it scales in|04-alb-asg]]  
✗ "The oldest instance" — wrong twice: zonal balance precedes the policy (so a newer instance can go first), and the default policy ranks configurations, not instance age; OldestInstance is a separate opt-in policy

**a SINGLE-Region load balancer needs a fixed address per AZ, or must preserve the client source IP without X-Forwarded-For**  
→ **Network Load Balancer — one static address per AZ, EIP attachable, client IP preserved natively** [[04-alb-asg#Worked examples|04-alb-asg]]  
✗ ALB — it gives a DNS name only, cannot take Elastic IPs for its subnets, and hands you X-Forwarded-For, which is an application change

**health checks fail, the instance is LEFT IN SERVICE and never replaced**  
→ **Turn on ELB health checks on the Auto Scaling group (HealthCheckType = ELB)** [[04-alb-asg#Worked examples|04-alb-asg]]  
✗ "The ALB terminates the unhealthy instance" — the ALB only stops routing; termination is the ASG's job and the ALB's verdict only reaches it once ELB health checks are on

**instances CHURN — terminated and relaunched every few minutes, never reaching a steady state**  
→ **Raise the health check grace period above the true time-to-healthy, or bake the app into the AMI** [[04-alb-asg#Worked examples|04-alb-asg]]  
✗ A scaling-policy or ALB misconfiguration — it looks like a scaling bug, but the ASG is honouring the ELB verdict while the instance is still bootstrapping

**unequal target counts per AZ behind an NLB, and the question asks what share each target receives**  
→ **Split per AZ first (DNS gives each AZ node an equal share), then within the AZ: 4 in AZ-A ⇒ 12.5% each, 6 in AZ-B ⇒ ~8.3% each** [[04-alb-asg#What cross-zone actually changes — the arithmetic|04-alb-asg]]  
✗ Dividing by the total target count (10% each) — that is the cross-zone-ON answer, and NLB cross-zone is off by default while ALB cross-zone is always on


## Monitoring  ·  14

**alarm on memory utilisation, swap, or free disk space on EC2**  
→ **Install the CloudWatch agent; those arrive as custom metrics** [[20-monitoring#⚠️ Traps — why the wrong answer looks right|20-monitoring]]  
✗ Enabling detailed monitoring — it changes the frequency (5 min → 1 min), never the set of metrics

**audit who read or wrote individual S3 objects (or who invoked a Lambda)**  
→ **Configure data events (an event selector) on a trail — they are opt-in and billed by volume** [[20-monitoring#⚠️ Traps — why the wrong answer looks right|20-monitoring]]  
✗ "Enable CloudTrail" alone, or the free 90-day Event history, which covers management events only

**install a third-party tool on hundreds of instances once, now, without SSH or RDP**  
→ **Systems Manager Run Command** [[20-monitoring#Which Systems Manager tool — the discrimination that actually gets tested|20-monitoring]]  
✗ Patch Manager (it updates existing software against a baseline), Maintenance Windows (it only says when, it never performs the work), State Manager (it holds a state over time, wrong for a one-off)

**instance unreachable because of a fault on the underlying host (power, network, hardware)**  
→ **A CloudWatch alarm action recover on StatusCheckFailed_System — it moves the instance to new hardware, keeping its instance ID and every IP including the public IPv4** [[20-monitoring#⚠️ Traps — why the wrong answer looks right|20-monitoring]]  
✗ reboot, which keeps the instance on the same broken host; and recover wired to StatusCheckFailed_Instance, which AWS does not permit. RAM contents are lost either way, and a terminated instance can never be recovered

**notify the security team 30 days before an imported third-party certificate expires, with least effort**  
→ **The AWS Config managed rule acm-certificate-expiration-check plus SNS (ACM does not auto-renew imported certificates)** [[20-monitoring#⚠️ Traps — why the wrong answer looks right|20-monitoring]]  
✗ Eliminating Config on principle — that is only right when the option describes a custom rule you must write. For ACM-issued certificates the DaysToExpiry alarm or an EventBridge rule on AWS Health events is the direct answer

**notify the team when a specific string appears in the application log**  
→ **Metric filter on the log group → custom metric → metric alarm → SNS** [[20-monitoring#Worked examples|20-monitoring]]  
✗ An alarm on the log group itself: alarms watch metrics, so the metric filter is the missing middle step

**notify us automatically when somebody calls a specific API, with the least machinery**  
→ **An EventBridge rule on the AWS API Call via CloudTrail detail-type targeting SNS — with a trail actively logging, the rule in the Region where the call happens, and ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS if the call is read-only** [[20-monitoring#Key facts, limits & pricing|20-monitoring]]  
✗ Shipping CloudTrail logs to S3 and querying with Athena, or a Lambda poller — both far heavier for "tell us when X happens"

**retain audit logs for seven years for compliance**  
→ **A trail delivering to S3, with S3 lifecycle to cheaper storage** [[20-monitoring#⚠️ Traps — why the wrong answer looks right|20-monitoring]]  
✗ CloudTrail Event history — that is 90 days, per Region, management events only, and is a console view not a retention setting

**run a containerised job when an event fires, or on a schedule**  
→ **An EventBridge rule targeting the ECS task directly (mapped through to ecs.RunTask)** [[20-monitoring#Key facts, limits & pricing|20-monitoring]]  
✗ A Lambda in between whose only job is to call RunTask — that is the distractor

**shell access to an instance in a private subnet with no bastion, no inbound port and no SSH key — and sessions must be auditable**  
→ **Systems Manager Session Manager, logging to S3 or CloudWatch Logs (plus interface VPC endpoints when the subnet has no internet access at all)** [[20-monitoring#Key facts, limits & pricing|20-monitoring]]  
✗ A bastion/jump host, an inbound SSH rule from the corporate CIDR, or distributing key pairs — all three are the old answer and all three are listed as distractors

**the alarm must trigger an Auto Scaling or EC2 action**  
→ **A metric alarm** [[20-monitoring#⚠️ Traps — why the wrong answer looks right|20-monitoring]]  
✗ A composite alarm — it exists to reduce alarm noise and cannot perform EC2 or Auto Scaling actions, only SNS

**the alarm sits in INSUFFICIENT_DATA and almost never evaluates on an EC2 instance**  
→ **The alarm period is shorter than the metric's resolution — use 300s, or enable detailed monitoring** [[20-monitoring#Worked examples|20-monitoring]]  
✗ Changing the threshold; and for a metric that simply stops publishing when idle, the fix is the missing-data treatment instead

**was this resource ever non-compliant during a past period / prove the configuration over time**  
→ **AWS Config — configuration items versioned over time, plus rules (and SSM Automation remediation)** [[20-monitoring#⚠️ Traps — why the wrong answer looks right|20-monitoring]]  
✗ CloudTrail: it records that PutBucketAcl was called, not what the ACL then was

**which user or role made this API call / who deleted it**  
→ **CloudTrail** [[20-monitoring#The four services — the discrimination the exam actually tests|20-monitoring]]  
✗ Config — it shows what the resource looked like before and after, but never the caller


## Networking  ·  72

**"attach an additional security group" offered as a way to RESTRICT access**  
→ **It cannot restrict — multiple SGs on an ENI combine as a union of allows, so adding one only widens access.** [[05-vpc-security#Key facts, limits & pricing|05-vpc-security]]  
✗ Reasoning by analogy with a NACL, where an added deny does narrow things.

**"restrict the NAT gateway's traffic with a security group"**  
→ **Impossible — a NAT gateway takes no security group; filter with the NACL on its subnet.** [[05-vpc-core#Why the NAT gateway has to live in a public subnet|05-vpc-core]]  
✗ NAT instance, which is an EC2 instance and does have a security group — that is how the distractor is made plausible.

**a 99.99% SLA is required for the Direct Connect link**  
→ **Maximum resiliency — separate connections terminating on separate devices in MORE THAN ONE location.** [[05-vpc-hybrid#Key facts, limits & pricing|05-vpc-hybrid]]  
✗ "Separate devices" in a single location, which is only the development-and-test model (no SLA tier); two single connections to multiple locations gives 99.9%.

**A and B are both peered to a shared-services VPC and still cannot reach each other**  
→ **Peering is non-transitive — peer A to B directly, or replace the mesh with a Transit Gateway.** [[05-vpc-endpoints-peering#Why peering never becomes a hub|05-vpc-endpoints-peering]]  
✗ "Add routes through the shared VPC" — no route can make peering transitive; traffic blackholes while the console reads "peered".

**a NACL deny rule exists but the bad traffic still gets through**  
→ **Rule ordering — the deny must be numbered LOWER than the allow it should override, because the first match ends evaluation.** [[05-vpc-security#Numbered rules, and first match wins|05-vpc-security]]  
✗ "A deny always beats an allow" (true on IAM, false on a NACL); numbering, not rule type, decides.

**a newly created and associated custom NACL killed all traffic in the subnet**  
→ **A custom NACL denies everything until you add numbered rules (both directions).** [[05-vpc-core#The defaults that behave backwards from what you create|05-vpc-core]]  
✗ The DEFAULT NACL, which allows all traffic in and out — the defaults and what you create behave opposite ways.

**a participant account in a shared VPC needs to create or accept a peering connection**  
→ **Only the VPC owner can — participants cannot work with peering connections.** [[05-vpc-endpoints-peering#Key facts, limits & pricing|05-vpc-endpoints-peering]]  
✗ Granting the participant an IAM permission; the restriction is in the VPC-sharing model, not IAM.

**a peered VPC wants internet access through our NAT gateway**  
→ **Not supported — you cannot route to a NAT gateway across a peering connection (no edge-to-edge routing).** [[05-vpc-core#Key facts, limits & pricing|05-vpc-core]]  
✗ "Just add a route to the NAT via the pcx" — the reverse direction (out through our NAT then across the peering) is the one that is fine.

**a private connection below 1 Gbps (e.g. 200 or 500 Mbps) is wanted**  
→ **A hosted connection through a Direct Connect partner (50 Mbps–25 Gbps in fixed steps).** [[05-vpc-hybrid#What a Direct Connect port actually carries|05-vpc-hybrid]]  
✗ A dedicated connection, which starts at 1 Gbps — hosted is the only route below that.

**a route-table target that steers traffic to a fleet of third-party inspection appliances**  
→ **A Gateway Load Balancer endpoint.** [[05-vpc-endpoints-peering#What problem does this solve?|05-vpc-endpoints-peering]]  
✗ A gateway endpoint — it is also a route-table target, which is exactly why it looks right and is not.

**a subnet was never associated with any route table**  
→ **It uses the VPC's main route table — which is why you never put an IGW route there, so forgotten subnets fail closed (private).** [[05-vpc-core#There is no public subnet checkbox|05-vpc-core]]  
✗ "It has no routing and is isolated" — it silently inherits the main route table's routes.

**an EC2 appliance must forward traffic on behalf of other instances and the traffic is being dropped**  
→ **Disable the source/destination check on its network interface.** [[05-vpc-core#Why one NAT gateway is not enough|05-vpc-core]]  
✗ Security group or NACL rules — the packets are dropped by the ENI's own check before any rule matters.

**application code must keep using the standard S3 hostnames with no change**  
→ **Gateway endpoint — it uses the same S3 DNS names.** [[05-vpc-endpoints-peering#The interface endpoint is an IP, not a route|05-vpc-endpoints-peering]]  
✗ S3 interface endpoint, which requires endpoint-specific DNS names (or private DNS, whose default sends only on-premises traffic over it).

**asymmetric packet drops appear after migrating from VPC peering to a Transit Gateway**  
→ **MTU mismatch — peering is 9001 intra-Region (8500 inter-Region), a transit gateway is 8500; update both VPCs together.** [[05-vpc-endpoints-peering#Why peering never becomes a hub|05-vpc-endpoints-peering]]  
✗ Looking for a routing or SG change; the symptom is size-dependent, so only some packets drop.

**both a free in-VPC path to S3 and a private path for on-premises traffic**  
→ **Use both in the same VPC — gateway endpoint for in-VPC traffic (free), interface endpoint for on-premises traffic (billed).** [[05-vpc-endpoints-peering#The interface endpoint is an IP, not a route|05-vpc-endpoints-peering]]  
✗ Replacing the gateway endpoint with an interface endpoint, which starts billing the in-VPC traffic that was free.

**connectivity needed quickly / temporarily / this week**  
→ **Site-to-Site VPN (minutes to hours), with a later cut-over to DX if throughput demands it.** [[05-vpc-hybrid#Worked examples|05-vpc-hybrid]]  
✗ Direct Connect, however much bandwidth the stem waves around — the physical cross-connect takes weeks to months.

**egress through the NAT breaks after a NACL is tightened on its subnet**  
→ **The NAT sources from ports 1024–65535, so the NACL must allow that ephemeral range.** [[05-vpc-core#Why the NAT gateway has to live in a public subnet|05-vpc-core]]  
✗ Blaming the private subnet's NACL or a missing SG rule on the NAT — the NAT has no SG and the filter is on its own subnet.

**EVERY target is unhealthy from the start, including a brand-new one, and nothing ever passes**  
→ **A NACL on the targets' subnet denying 0.0.0.0/0 or the subnet's own CIDR blocks the health checks.** [[05-vpc-security#Numbered rules, and first match wins|05-vpc-security]]  
✗ Target group settings or the instance's security group — the cause sits a layer away, on the subnet.

**everything launched in the DEFAULT VPC is internet-facing with no configuration**  
→ **The default VPC's main route table already carries 0.0.0.0/0 → IGW.** [[05-vpc-core#There is no public subnet checkbox|05-vpc-core]]  
✗ Treating "never route the main RT to an IGW" as an AWS prohibition — it is a convention you adopt; AWS's own default VPC ships the opposite way.

**expose OUR OWN application privately to consumer VPCs or other accounts, without peering and without exposing the rest of the VPC**  
→ **A PrivateLink endpoint service fronted by an NLB (or Gateway Load Balancer); consumers create interface endpoints, and the provider must grant access first.** [[05-vpc-endpoints-peering#The interface endpoint is an IP, not a route|05-vpc-endpoints-peering]]  
✗ Putting an ALB behind PrivateLink directly — only legal as an ALB registered as a target of the NLB.

**flow logs look empty right after a test, or the requirement says real-time**  
→ **Expect minutes — about 5 to CloudWatch Logs and 10 to S3, best effort; flow logs are not a real-time stream.** [[05-vpc-security#Key facts, limits & pricing|05-vpc-security]]  
✗ Reading the silence as "the traffic was blocked" or as evidence of no traffic.

**fragmented TCP or ICMP packets must traverse the NAT, or an IPsec tunnel must pass through it**  
→ **NAT instance — the managed NAT gateway supports neither TCP/ICMP fragmentation nor IPsec (NAT-T over UDP only).** [[05-vpc-core#NAT Gateway vs NAT Instance|05-vpc-core]]  
✗ NAT gateway, which is otherwise always the default; this is AWS's own documented reason to pick the instance.

**growing number of VPCs, simplify connectivity, and connect on-premises too**  
→ **Transit Gateway — one attachment per VPC/VPN/DX, transitive, segmented with TGW route tables.** [[05-vpc-endpoints-peering#The mesh math, and what Transit Gateway replaces|05-vpc-endpoints-peering]]  
✗ More peering connections: a full mesh is N(N-1)/2 (12 VPCs = 66) with routes on both sides of each.

**inbound rule is in place, the request arrives, but the response never comes back / the page hangs**  
→ **The NACL is stateless — add the outbound rule for the ephemeral return range 1024–65535.** [[05-vpc-security#Stateful versus stateless|05-vpc-security]]  
✗ Mirroring the security group's rules onto the NACL; the SG handled return traffic for free and the NACL never will.

**individual remote employees' laptops need access to the VPC**  
→ **AWS Client VPN (OpenVPN-based).** [[05-vpc-hybrid#Worked examples|05-vpc-hybrid]]  
✗ Site-to-Site VPN, which joins whole networks — one device versus one building.

**instances get no public DNS hostname in a VPC you built yourself**  
→ **enableDnsHostnames defaults to false in a custom VPC — turn it on (enableDnsSupport is already true).** [[05-vpc-core#The defaults that behave backwards from what you create|05-vpc-core]]  
✗ Blaming enableDnsSupport, which defaults to true; and a default VPC has hostnames on, which is why it "works there".

**instances were given public IPs but still cannot be reached from the internet**  
→ **The subnet is private — its route table has no 0.0.0.0/0 route to the internet gateway. Add the IGW route (or move them to a public subnet).** [[05-vpc-core#There is no public subnet checkbox|05-vpc-core]]  
✗ "Assign an Elastic IP" — the stem already gave them public addresses, so the broken half is routing, not addressing.

**INTER-REGION peering, and the database tier's rule must permit the app tier in the other VPC**  
→ **Write the rule against the peer VPC's CIDR block — a cross-Region peer's security group cannot be referenced.** [[05-vpc-endpoints-peering#Key facts, limits & pricing|05-vpc-endpoints-peering]]  
✗ Referencing the peer's security group id, which is legal only for same-Region peering (including cross-account, as 123456789012/sg-…); cross-Region it is impossible, not merely untidy.

**IPsec over Direct Connect but NO public IP addresses are to be used**  
→ **Private IP VPN over a transit VIF — requires a Direct Connect gateway plus a transit gateway, and raises route limits to 5000 out / 1000 in.** [[05-vpc-hybrid#Private is not the same as encrypted|05-vpc-hybrid]]  
✗ The classic VPN over a public VIF, which needs public IPs and opens access between all AWS public services and on-prem.

**IPv6 workloads need outbound internet access but must not be reachable from the internet**  
→ **Egress-only internet gateway (VPC edge, free, no security group).** [[05-vpc-core#Key facts, limits & pricing|05-vpc-core]]  
✗ NAT gateway — it performs no IPv6-to-IPv6 translation, because IPv6 addresses are already globally routable.

**IPv6-only clients must reach an IPv4-only destination**  
→ **NAT gateway — it does NAT64 (paired with Route 53 Resolver DNS64).** [[05-vpc-core#Key facts, limits & pricing|05-vpc-core]]  
✗ Egress-only IGW — IPv6-only, no translation, so it cannot bridge to an IPv4 service.

**long-idle connections through the NAT are dropped and the client sees a connection reset**  
→ **The NAT gateway's 350-second idle timeout, which returns an RST (not a FIN) — use TCP keepalives or a NAT instance with a tunable timeout.** [[05-vpc-core#NAT Gateway vs NAT Instance|05-vpc-core]]  
✗ A security group or NACL change — neither has an idle timeout you can set.

**MACsec offered as the way to satisfy end-to-end encryption to the VPC**  
→ **It is not — MACsec encrypts only the Layer 2 cross-connect into AWS (10/100/400 Gbps dedicated, never hosted).** [[05-vpc-hybrid#Private is not the same as encrypted|05-vpc-hybrid]]  
✗ Treating MACsec as equivalent to VPN-over-DX; it does not cover the path to your VPC.

**many accounts in the same AWS Organization must launch resources into ONE network with the least operational overhead**  
→ **VPC sharing via AWS RAM — the owner shares subnets with participant accounts, using the VPC's implicit routing.** [[05-vpc-endpoints-peering#Key facts, limits & pricing|05-vpc-endpoints-peering]]  
✗ Peering or Transit Gateway (both add connections to pay for and maintain); and any option saying "share the VPC" — only subnets are shared.

**more VPN throughput by aggregating tunnels (ECMP)**  
→ **ECMP over a transit gateway — and it requires dynamic BGP routing.** [[05-vpc-hybrid#Key facts, limits & pricing|05-vpc-hybrid]]  
✗ Static routing, which cannot do ECMP at all.

**multiple branch offices must connect to AWS and to each other over VPN**  
→ **VPN CloudHub — hub-and-spoke on a VGW using BGP.** [[05-vpc-hybrid#Key facts, limits & pricing|05-vpc-hybrid]]  
✗ A Transit Gateway, which is the answer when many VPCs (not just branch sites) are in play.

**must block one specific abusive IP address or CIDR, regardless of instance security groups**  
→ **A NACL inbound DENY rule on the subnet.** [[05-vpc-security#Security Group vs Network ACL (the exam's favorite table)|05-vpc-security]]  
✗ A security group "deny" rule — SGs are allow-only, so they cannot express a block at all.

**must change an existing flow log's fields, format or IAM role**  
→ **Not possible — delete the flow log and create a new one.** [[05-vpc-security#Key facts, limits & pricing|05-vpc-security]]  
✗ "Modify the flow log configuration" — a flow log is immutable once created.

**must determine WHAT DATA left the network / inspect request contents or filenames**  
→ **Network Firewall (deep packet inspection) or VPC Traffic Mirroring for packet capture.** [[05-vpc-security#What flow logs can and cannot tell you|05-vpc-security]]  
✗ VPC Flow Logs — metadata only (IPs, ports, bytes, ACCEPT/REJECT), never payload. A very common distractor.

**must stop instances from reaching the instance metadata endpoint 169.254.169.254**  
→ **The instance's own metadata options (e.g. disable IMDS / enforce IMDSv2).** [[05-vpc-security#Ephemeral ports, and which direction to open them|05-vpc-security]]  
✗ A NACL deny for 169.254.169.254 — a NACL cannot block IMDS traffic.

**NACL for a server that RECEIVES requests — which direction gets the ephemeral range**  
→ **Outbound, because its reply travels to the client's ephemeral port.** [[05-vpc-security#Ephemeral ports, and which direction to open them|05-vpc-security]]  
✗ Inbound ephemeral, which is what an instance that initiates connections needs; getting the direction backwards is the standard error.

**NACL for an instance that CALLS out to an API or resolver — which direction gets the ephemeral range**  
→ **Inbound, because the answer returns to its own ephemeral port.** [[05-vpc-security#Ephemeral ports, and which direction to open them|05-vpc-security]]  
✗ Outbound ephemeral, which belongs to a server answering requests.

**NAT gateway is dropping packets at peak load / throughput limit reached**  
→ **Split the workload across subnets, each with its own NAT gateway — a single NAT caps at 100 Gbps and 10M packets/sec.** [[05-vpc-core#Key facts, limits & pricing|05-vpc-core]]  
✗ "Resize the NAT gateway" — there is no instance size to change; scaling is horizontal.

**NAT gateway lands in Failed state and then disappears on its own**  
→ **The VPC has no internet gateway attached at all; a failed NAT gateway auto-deletes after about an hour.** [[05-vpc-core#Why the NAT gateway has to live in a public subnet|05-vpc-core]]  
✗ A routing misconfiguration — that creates successfully and fails silently instead.

**NAT gateway shows as available with no error, but private instances silently have no internet**  
→ **The NAT sits in a private subnet (or the NAT's own subnet routes 0.0.0.0/0 back at the NAT) — it must live in a public subnet whose RT points at the IGW.** [[05-vpc-core#Why the NAT gateway has to live in a public subnet|05-vpc-core]]  
✗ A NAT in Failed state — that is the "no IGW in the VPC at all" case and it does report an error; the misplaced-NAT case reports nothing.

**need to know whether traffic WOULD reach a resource, and which hop blocks it, without sending any traffic**  
→ **VPC Reachability Analyzer (static configuration analysis, hop-by-hop, names the blocking component).** [[05-vpc-security#What flow logs can and cannot tell you|05-vpc-security]]  
✗ VPC Flow Logs — they are after-the-fact evidence of traffic that actually flowed, and an empty log proves nothing.

**needs the performance of a private circuit AND in-transit encryption (auditor/compliance wording)**  
→ **A Site-to-Site VPN running over the Direct Connect — DX alone carries plaintext.** [[05-vpc-hybrid#Worked examples|05-vpc-hybrid]]  
✗ Direct Connect by itself, because "private" reads as "secure"; private is not encrypted.

**Network Firewall is deployed and billing but inspecting nothing, or asks what else may live in the firewall subnet**  
→ **Nothing else — the firewall subnet is dedicated, and traffic only reaches the endpoint because route tables send it there.** [[05-vpc-security#Network Firewall, and why it needs a subnet of its own|05-vpc-security]]  
✗ Treating Network Firewall as a setting you enable on an existing subnet; without the route-table change it sees no packets.

**NTP or external DNS stops working after a NACL is applied, showing outbound REJECT lines**  
→ **The rule set is TCP-only — NACL rules name a protocol, so UDP is dropped outright.** [[05-vpc-security#Ephemeral ports, and which direction to open them|05-vpc-security]]  
✗ Blaming the ephemeral range; the range may be fine while the protocol is wrong. (Note: it cannot be the Amazon-provided resolver, which a NACL cannot filter at all.)

**on-premises traffic arriving over Site-to-Site VPN or Direct Connect must use the VPC's NAT gateway for internet egress**  
→ **Not possible through a virtual private gateway — terminate on a transit gateway instead and it works.** [[05-vpc-core#Key facts, limits & pricing|05-vpc-core]]  
✗ Assuming any hybrid path can use the NAT; the restriction is specifically the VGW.

**one AZ went down and private subnets in EVERY AZ lost outbound internet**  
→ **Single shared NAT gateway — deploy one NAT gateway per AZ and point each AZ's private route table at its local NAT.** [[05-vpc-core#Why one NAT gateway is not enough|05-vpc-core]]  
✗ "A NAT gateway is already redundant" — it is redundant only within its own AZ, and cross-AZ traffic to it is billed.

**ONE private connection must reach VPCs in MULTIPLE Regions (and accounts)**  
→ **Direct Connect Gateway — private VIF → DXGW → multiple VGWs across any Region or account.** [[05-vpc-hybrid#Key facts, limits & pricing|05-vpc-hybrid]]  
✗ Transit Gateway alone (regional) or a second DX circuit; and you do not need two DXGWs for HA, it sits outside the data path.

**one VPN connection must serve several VPCs**  
→ **Terminate on a transit gateway instead of a VGW (a VPC holds one VGW, and a VGW caps at 10 VPN connections).** [[05-vpc-hybrid#Key facts, limits & pricing|05-vpc-hybrid]]  
✗ More VPN connections to the same VGW, or a VGW per VPC — AWS's own advice is to move to a TGW.

**peered instances resolve each other to public addresses and the traffic takes the long way round**  
→ **Enable DNS resolution on the peering connection so the hostname resolves to the private IP (mandatory for inter-Region peering).** [[05-vpc-endpoints-peering#Why peering never becomes a hub|05-vpc-endpoints-peering]]  
✗ Blaming route tables; the routes are fine and DNS is sending the packets elsewhere.

**private access to SQS, KMS, Secrets Manager or almost any other AWS service**  
→ **Interface endpoint (PrivateLink ENI with a private IP, secured by a security group).** [[05-vpc-endpoints-peering#Worked examples|05-vpc-endpoints-peering]]  
✗ Gateway endpoint — it exists only for S3 and DynamoDB.

**private instances push/pull large volumes to S3 all day and the goal is to cut data-transfer cost**  
→ **S3 gateway endpoint on the private route table — free, and the NAT gateway can be deleted if S3 was its only purpose.** [[05-vpc-endpoints-peering#Worked examples|05-vpc-endpoints-peering]]  
✗ Interface endpoint, which bills hourly per AZ plus per GB; and keeping the NAT, whose per-GB charge is the thing being paid for.

**private S3 access needed FROM ON-PREMISES over Direct Connect/VPN, or from a peered VPC**  
→ **S3 interface endpoint — it is reachable across peering, VPN and Direct Connect.** [[05-vpc-endpoints-peering#Worked examples|05-vpc-endpoints-peering]]  
✗ S3 gateway endpoint, the usual free answer; it works only from inside the VPC that owns the route table.

**share hybrid/inter-VPC connectivity with another account via RAM**  
→ **Share the transit gateway itself; the participant account then creates its own attachment to it.** [[05-vpc-endpoints-peering#Key facts, limits & pricing|05-vpc-endpoints-peering]]  
✗ "Share the TGW attachment" — there is no attachment resource type in RAM's shareable list.

**the BUCKET must reject every request that did not arrive through our VPC endpoint**  
→ **An S3 bucket policy with the aws:sourceVpce condition key.** [[05-vpc-endpoints-peering#Key facts, limits & pricing|05-vpc-endpoints-peering]]  
✗ A VPC endpoint policy — that limits what the endpoint may reach, not what may reach the bucket; the two face opposite directions.

**the gateway endpoint is in place but calls to a bucket in ANOTHER Region still leave via the internet gateway**  
→ **Expected — prefix lists are Region-specific, so a gateway endpoint does nothing for cross-Region S3.** [[05-vpc-endpoints-peering#The gateway endpoint is a route, not a box|05-vpc-endpoints-peering]]  
✗ Blaming the route table or longest-prefix match; the endpoint route simply does not cover another Region's ranges.

**the NAT device must also act as a bastion host, or cost at very small scale is the stated driver**  
→ **NAT instance (legacy EC2) — it has a security group and can double as a bastion.** [[05-vpc-core#Why one NAT gateway is not enough|05-vpc-core]]  
✗ NAT gateway, the default answer everywhere else; it cannot port-forward or act as a bastion.

**the on-premises router sits behind NAT or has no public address**  
→ **Register the NAT device's address — the CGW requires a STATIC IP (v4 or v6), not necessarily a public one; with AWS Private CA certificate auth no IP is needed.** [[05-vpc-hybrid#The two endpoints, and why one of them isn't a device|05-vpc-hybrid]]  
✗ "A public IP is required" — AWS's requirement is static, which is what the distractor overstates.

**the peer VPC should reach the internet (or on-prem, or S3) through our gateways**  
→ **No edge-to-edge routing — a peer cannot use your IGW, NAT device, VPN, Direct Connect or gateway endpoint.** [[05-vpc-endpoints-peering#Why peering never becomes a hub|05-vpc-endpoints-peering]]  
✗ Adding a route for it; the limit is structural, not a missing route.

**the rule must reference a managed prefix list (pl-…) or another security group**  
→ **A security group rule — it accepts a CIDR, another SG, or a prefix list.** [[05-vpc-security#Security Group vs Network ACL (the exam's favorite table)|05-vpc-security]]  
✗ A NACL, which takes CIDR only and cannot reference prefix lists or security groups.

**the stem names DNS, the Amazon-provided resolver (VPC+2), or wants a domain allowlist/denylist AT RESOLUTION TIME**  
→ **Route 53 Resolver DNS Firewall.** [[05-vpc-security#Ephemeral ports, and which direction to open them|05-vpc-security]]  
✗ A NACL or security group rule — neither layer filters traffic to the Amazon-provided resolver at all.

**the stem wants the TRAFFIC ITSELF stopped (TLS SNI / HTTP Host), names IPS / Suricata / attack patterns, or the client could bypass DNS with a hard-coded IP**  
→ **AWS Network Firewall (Suricata IPS, domain filtering) in a dedicated firewall subnet.** [[05-vpc-security#Network Firewall, and why it needs a subnet of its own|05-vpc-security]]  
✗ Security groups or NACLs — they only know IP and port, and a domain name is not an address.

**the subnet already has a 0.0.0.0/0 route to the internet gateway, yet nothing is reachable**  
→ **The instances have no public IPv4 or Elastic IP — enable auto-assign public IPv4 or attach an EIP.** [[05-vpc-core#There is no public subnet checkbox|05-vpc-core]]  
✗ "Add an internet gateway route" — it has one; label (public) and reachability are two separate conditions.

**the subnet must support exactly N hosts / "we need 256 addresses in this subnet"**  
→ **Size up — AWS reserves 5 addresses in every subnet, so a /24 yields 251 usable, not 256.** [[05-vpc-core#The address space, and the five IPs you never get|05-vpc-core]]  
✗ Doing plain 2^(32-prefix) arithmetic; the trap is pure sizing, you come up five short.

**the two VPCs to be connected have matching or overlapping CIDR blocks**  
→ **Peering is impossible — re-address one VPC, or use PrivateLink/another pattern.** [[05-vpc-endpoints-peering#Why peering never becomes a hub|05-vpc-endpoints-peering]]  
✗ "Peer them and route only the non-overlapping ranges" — overlap in ANY of a VPC's CIDR blocks blocks the connection outright.

**the VPC has run out of IP space and needs a bigger address range**  
→ **Add a secondary, non-overlapping CIDR block (/16–/28) — you cannot resize the existing one.** [[05-vpc-core#Key facts, limits & pricing|05-vpc-core]]  
✗ "Change the VPC CIDR to a larger prefix" — AWS does not allow growing or shrinking an existing block.

**VPCs attached to the same Direct Connect gateway must NOT be able to talk to each other**  
→ **A DXGW is non-transitive by design — but check the stem: a supernet advertised from on-prem across those VPCs (Nov 2021) makes them mutually reachable, and the TGW case needs a blackhole route table.** [[05-vpc-hybrid#Key facts, limits & pricing|05-vpc-hybrid]]  
✗ Reading non-transitivity as absolute; advertise more specific prefixes, use SGs, or give each VPC its own DXGW.

**which virtual interface — one VPC, AWS public services, or a Transit Gateway**  
→ **Private VIF → one VPC via a VGW; Public VIF → AWS public services globally; Transit VIF → a TGW via a DX gateway.** [[05-vpc-hybrid#What a Direct Connect port actually carries|05-vpc-hybrid]]  
✗ Assuming the port alone reaches anything; the VIF type is what the question hinges on (and VPN-over-DX uses public, private IP VPN uses transit).


## Other services  ·  19

**a containerised job that runs for hours (genomics, rendering, simulation), ideally on Spot**  
→ **AWS Batch** [[24-other-services#AWS Batch — containerised batch jobs at any scale|24-other-services]]  
✗ Lambda — answer 15 minutes as the exam's ceiling. Inverse trap: a short, spiky, event-driven workload put on Batch is over-engineering, because Batch has queue and provisioning latency

**a SaaS or consumer application's own end users, social sign-in, scaling to millions**  
→ **Amazon Cognito** [[24-other-services#Traps|24-other-services]]  
✗ Directory Service in any flavour — that is workforce identity for employees and domain-joined machines

**a workflow that pauses for a human approval that may take days, and every step must be auditable**  
→ **Step Functions Standard, using Wait for Callback (.waitForTaskToken)** [[24-other-services#Traps|24-other-services]]  
✗ Express — capped at five minutes, Request Response only (no .waitForTaskToken), and never exactly-once

**after signing in, the mobile app calls S3 or DynamoDB directly — or needs guest/unauthenticated access**  
→ **A Cognito identity pool, which exchanges a trusted token for temporary AWS credentials via STS** [[24-other-services#Amazon Cognito — two pools that do different jobs|24-other-services]]  
✗ A user pool alone — it authenticates people and issues JWTs but mints no AWS credentials (the ALB's built-in Cognito authentication is also a user-pool integration)

**authenticate users before the request ever reaches the application servers**  
→ **An Application Load Balancer listener rule with built-in Cognito user pool authentication** [[24-other-services#Amazon Cognito — two pools that do different jobs|24-other-services]]  
✗ Building auth into the application, or an identity pool, which has no part in that integration

**B2B/EDI file exchange with supply-chain, payments or ERP partners**  
→ **AS2 on AWS Transfer Family** [[24-other-services#AWS Transfer Family — SFTP as a managed service|24-other-services]]  
✗ SFTP/FTPS, which carry no EDI framing, and DataSync, which speaks none of these protocols

**containerise an existing commercial off-the-shelf application with no source code available**  
→ **AWS App2Container — it inspects the running app and generates OCI images** [[24-other-services#Key facts, limits & pricing|24-other-services]]  
✗ App Runner, which is only a runtime: it runs an image or an already-buildable repo and cannot containerise anything

**continuously consolidate several live RDS databases into a data warehouse, least development effort, no infrastructure to manage**  
→ **DMS with Redshift as the target (CDC natively)** [[24-other-services#Key facts, limits & pricing|24-other-services]]  
✗ Glue (batch ETL and a catalogue, not change data capture), EMR (a cluster the stem did not want), Kinesis Data Streams (producers and consumers you still write)

**deploy a web app quickly with minimal setup while keeping control of the EC2 instances, ASG and load balancer, at no extra service cost**  
→ **Elastic Beanstalk** [[24-other-services#Traps|24-other-services]]  
✗ Rejecting it over an imagined service charge or because it "hides" the infrastructure — it is free and the resources stay in your account; a fully managed container service is the genuinely more abstracted option

**deploy the same baseline into many accounts and Regions in one operation**  
→ **CloudFormation StackSets (from an admin account or via Organizations)** [[24-other-services#AWS CloudFormation — the standardisation answer|24-other-services]]  
✗ Running the template per account by hand; and for "let teams self-serve only pre-approved configurations" the answer is Service Catalog, not raw CloudFormation

**external partners upload over SFTP/FTPS/FTP/AS2 and cannot change their clients**  
→ **AWS Transfer Family, landing files directly in S3 or EFS** [[24-other-services#Traps|24-other-services]]  
✗ DataSync — a transfer job you run to move a dataset between storage systems, not a standing protocol endpoint. If the stem names a protocol, it is Transfer Family

**keep (or snapshot) a database when its CloudFormation stack is deleted**  
→ **A DeletionPolicy of Retain, or Snapshot to take one first** [[24-other-services#AWS CloudFormation — the standardisation answer|24-other-services]]  
✗ Relying on the default, which is Delete

**move a large on-premises Oracle database to Aurora PostgreSQL with only minutes of downtime**  
→ **AWS SCT (or DMS Schema Conversion) for the schema, then DMS full load plus ongoing replication (CDC) until cutover** [[24-other-services#AWS DMS — the migration answer, and the biggest gap here|24-other-services]]  
✗ DMS alone — it moves data, not schema, so it is complete only when source and target run the same engine; and "export a dump and restore it" blows the downtime budget at that size

**on-premises users must sign in with existing credentials AND the options are the three Directory Service flavours — the axis is where the user records live**  
→ **AD Connector — a proxy that forwards sign-in requests to your on-premises domain controllers** [[24-other-services#AWS Directory Service — three options, one real discriminator|24-other-services]]  
✗ Managed Microsoft AD (a real directory in AWS, more than asked) and Simple AD (a standalone Samba 4 directory, which stores its own users)

**one client call must read and write across several DynamoDB tables, most operationally efficient, without hurting baseline performance**  
→ **An AppSync pipeline resolver (functions chained server-side, each against a data source)** [[24-other-services#AWS AppSync — managed GraphQL|24-other-services]]  
✗ A Lambda behind API Gateway fanning out (you write the logic, heavier ops), Athena Federated Query (analytical SQL, far too slow for a request path), CloudFront Functions (cannot reach DynamoDB at all)

**replication volume that varies or spikes, with least operational overhead**  
→ **DMS Serverless — a replication configuration that auto-provisions and auto-scales** [[24-other-services#Key facts, limits & pricing|24-other-services]]  
✗ A sized DMS replication instance, which leaves you doing capacity estimation and engine patching

**the API style is GraphQL, or a mobile app needs real-time data and offline sync**  
→ **AWS AppSync (subscriptions over serverless WebSockets; Amplify is built on it)** [[24-other-services#AWS AppSync — managed GraphQL|24-other-services]]  
✗ API Gateway — REST, HTTP and WebSocket APIs, not GraphQL

**the directory must work with Amazon RDS for SQL Server (or needs trusts, schema extensions, LDAPS or MFA)**  
→ **AWS Managed Microsoft AD** [[24-other-services#Traps|24-other-services]]  
✗ AD Connector and Simple AD — both explicitly incompatible with RDS for SQL Server, and Simple AD supports none of trusts, schema extensions, LDAPS or MFA

**tightly coupled HPC with MPI AND the options are services that RUN the job — "one submission", "gang scheduling", "minimal operational overhead"**  
→ **AWS Batch multi-node parallel jobs (gang scheduling, one submission, a main node plus children)** [[24-other-services#Key facts, limits & pricing|24-other-services]]  
✗ An Auto Scaling group, a CloudFormation-managed cluster placement group, or Elastic Beanstalk — all leave you building the coordination


## Resilience & DR  ·  8

**a bad deployment, ransomware or an accidental deletion has already been copied into the DR Region**  
→ **Point-in-time recovery, versioning or immutable backups (backup & restore is the strategy whose design is an untouched copy)** [[14-dr-resilience#Traps|14-dr-resilience]]  
✗ More cross-Region replication — it copies corruption and deletions faithfully, so there is nothing to fail over to

**a contractual or SLA-backed replication time for S3 cross-Region replication**  
→ **S3 Replication Time Control (RTC) — 15 minutes, SLA-backed** [[14-dr-resilience#Key facts, limits & pricing|14-dr-resilience]]  
✗ Plain CRR, which is seconds-to-minutes but carries no commitment

**a DR game day where the failover worked but the DR Region could not reach production capacity**  
→ **Pre-provision full capacity (static stability) and raise the DR Region's service quotas ahead of time** [[14-dr-resilience#Traps|14-dr-resilience]]  
✗ Tuning the Auto Scaling policy — scaling is the control-plane dependency that caused it, and unraised quotas cap it anyway

**an aggressive RTO where the alarm itself is slow to fire**  
→ **Deep health checks against real KPIs — detection, notification, escalation and declaration all sit inside the RTO budget** [[14-dr-resilience#Traps|14-dr-resilience]]  
✗ Budgeting the RTO for the failover alone, or a shallow heartbeat that returns 200 while the database is unreachable

**cross-Region recovery for a relational database with sub-minute failover and seconds of data loss**  
→ **Aurora Global Database** [[14-dr-resilience#Traps|14-dr-resilience]]  
✗ RDS cross-Region read replica — promotion takes a few minutes and includes a reboot, which is the planted distractor whenever the RTO/RPO is aggressive

**data-residency or sovereignty rules confine the workload to a country with only one AWS Region**  
→ **Implement the same four-strategy choice across that Region's Availability Zones as the discrete locations** [[14-dr-resilience#Traps|14-dr-resilience]]  
✗ Concluding DR is impossible, or replicating to a Region in another country and breaking compliance

**the DR Region already runs a smaller working copy and recovery needs only a scale-up**  
→ **Warm standby** [[14-dr-resilience#Traps|14-dr-resilience]]  
✗ Pilot light — its servers are switched off, so it cannot serve a request until you turn something on

**the MOST resilient failover mechanism during a regional event**  
→ **Route 53 health checks, or Application Recovery Controller switches — data-plane operations** [[14-dr-resilience#Traps|14-dr-resilience]]  
✗ Changing Route 53 weights, moving a Global Accelerator traffic dial, or depending on Auto Scaling to reach capacity: all control plane, and control planes are likeliest to be degraded exactly then


## Security & compliance  ·  35

**"continuously evaluate configuration and remediate automatically" / "configuration history" / "drift detection"**  
→ **AWS Config (rules + SSM Automation remediation)** [[25-well-architected#WA Tool vs Trusted Advisor vs Config — three things that "check your account"|25-well-architected]]  
✗ Trusted Advisor — it recommends and does not enforce, and on Basic it will not even refresh Security checks automatically

**"after rotation, do we have to re-encrypt the data / will applications need changing?"**  
→ **No — rotation changes key material only; old material is retained and the key ID never changes** [[21-security#How it actually works|21-security]]  
✗ "Rotation re-encrypts the data" or "rotates the data keys" — it does neither

**"alert us when a high-severity GuardDuty finding appears"**  
→ **Finding → EventBridge rule → SNS/Lambda** [[21-security#⚠️ Traps — why the wrong answer looks right|21-security]]  
✗ A CloudWatch alarm — GuardDuty does publish metrics, but they are usage, cost and scan metrics; none of them counts findings or severity (so don't eliminate the alarm option by claiming GuardDuty has no metrics either)

**"block a source making 100 requests per second while normal users make about 10"**  
→ **A WAF rate-based rule** [[21-security#Rate limiting is a WAF feature, and disabling GuardDuty destroys findings|21-security]]  
✗ Shield Advanced — it adds DDoS cost protection, richer L3/L4 detection and the SRT, but gives you no configurable request-rate threshold (it appears as an option because it bundles WAF)

**"block traffic from these countries" where the architecture is an ALB with no CloudFront**  
→ **WAF geo match rule statement on a web ACL attached to the ALB** [[21-security#⚠️ Traps — why the wrong answer looks right|21-security]]  
✗ CloudFront Geo Restriction — it is a property of a distribution and does not exist when there is no distribution (if CloudFront is in the path, it is the cheaper option)

**"centrally configure and keep WAF / Shield / security-group rules consistent across all accounts in the organization"**  
→ **AWS Firewall Manager** [[21-security#Which detection service|21-security]]  
✗ WAF directly — that is the answer for one account, one Region

**"certificates keep expiring / we want renewal to be automatic"**  
→ **ACM-issued certificate with DNS validation (email validation needs a human each time)** [[21-security#Key facts, limits & pricing|21-security]]  
✗ An imported third-party certificate — it behaves like an ACM one except that ACM provides no managed renewal for it

**"detect IAM access keys older than 90 days and deactivate them automatically"**  
→ **Config managed rule access-keys-rotated (Periodic, AWS::IAM::User, maxAccessKeyAge default 90) → EventBridge compliance-change event → Lambda** [[21-security#Key facts, limits & pricing|21-security]]  
✗ Expecting it to cover the root user's access keys — it does not; root keys need a different control

**"enable automatic rotation on this asymmetric / HMAC / custom-key-store key"**  
→ **Not possible — rotate manually (new key, repoint the alias)** [[21-security#⚠️ Traps — why the wrong answer looks right|21-security]]  
✗ Assuming the 365-day automatic rotation applies to every KMS key; it is only for symmetric keys whose material KMS generated

**"encode our own organisation's standards into the review"**  
→ **A custom lens in the Well-Architected Tool** [[25-well-architected#AWS Well-Architected Tool — the free self-assessment|25-well-architected]]  
✗ The AWS-provided lenses (serverless, SaaS, financial services, ML) — those are AWS's question sets, not yours

**"encrypt objects far larger than 4 KB with our own KMS key"**  
→ **Envelope encryption — GenerateDataKey, encrypt locally with the plaintext data key, store the encrypted copy beside the ciphertext** [[21-security#How it actually works|21-security]]  
✗ Calling KMS Encrypt on the object — the symmetric plaintext limit is 4,096 bytes, which is the reason envelope encryption exists

**"filter SQL injection / XSS / bad bots" but the architecture has a Network Load Balancer**  
→ **WAF cannot attach to an NLB — something in the architecture must change (put an ALB or CloudFront in the path)** [[21-security#⚠️ Traps — why the wrong answer looks right|21-security]]  
✗ "Attach a web ACL to the NLB" or "to the EC2 instance" — WAF inspects HTTP(S) and an NLB is layer 4; also note Shield is DDoS, not where rules live

**"find credit-card numbers / PII in our storage"**  
→ **Macie — but only if the data is in S3** [[21-security#⚠️ Traps — why the wrong answer looks right|21-security]]  
✗ Macie offered for RDS, EBS, DynamoDB or EFS data — it scans S3 objects only, so if the data is elsewhere Macie is the distractor

**"HTTPS in a Region that ACM does not support"**  
→ **The legacy IAM server-certificate store (API-only; the certificate must come from an external provider)** [[21-security#Key facts, limits & pricing|21-security]]  
✗ ACM itself, or expecting to manage it in the IAM console — you cannot, and you cannot upload an ACM certificate into IAM

**"internal / private PKI", certificates for internal services**  
→ **ACM Private CA (a separate, paid service)** [[21-security#ACM — where the certificate has to live|21-security]]  
✗ Free public ACM certificates — they are for public TLS endpoints; Private CA is the answer only when the stem says internal/private

**"investigate the root cause of this finding" / "visualise the relationships between the entities involved"**  
→ **Amazon Detective** [[21-security#Which detection service|21-security]]  
✗ Security Hub — it aggregates and prioritises findings into one view; it does not do the causal investigation

**"is DynamoDB data encrypted, and can we turn it off?"**  
→ **Always encrypted, no off switch; the default is an AWS owned key and you may switch to AWS managed or customer managed** [[21-security#How it actually works|21-security]]  
✗ Treating encryption as an option to enable — and note DAX at-rest encryption is the neighbour that uses an AWS managed key

**"reduce cost while maintaining availability" (two pillars named in one sentence)**  
→ **Cost Optimization is the objective and Reliability is the constraint — so right-size / commit, never collapse to one instance or one AZ** [[25-well-architected#Worked examples|25-well-architected]]  
✗ Any option that saves money by dropping to a single AZ or instance (breaks the constraint), or that improves performance without reducing spend (ignores the objective)

**"review our architecture / this workload's design against AWS best practices"**  
→ **AWS Well-Architected Tool (free, question-driven, per workload)** [[25-well-architected#WA Tool vs Trusted Advisor vs AWS Config|25-well-architected]]  
✗ Trusted Advisor — it never sees your intent, only your deployed resources

**"revoke access to the encrypted data immediately"**  
→ **Change the key policy / IAM policy, or disable the key — all immediate and reversible** [[21-security#⚠️ Traps — why the wrong answer looks right|21-security]]  
✗ "Schedule the key for deletion" — the minimum wait is 7 days (default 30), so it is neither fast nor reversible once complete

**"share the encrypted snapshot / AMI with another account"**  
→ **Re-encrypt under a customer managed key and name the other account in the key policy** [[21-security#Worked examples|21-security]]  
✗ Fixing IAM permissions, or using the default aws/rds AWS managed key — you cannot edit its key policy at all, so no permissions change can rescue it

**"stop using GuardDuty but keep the findings we already have"**  
→ **Suspend it (or export the findings to S3 first, then disable)** [[21-security#Rate limiting is a WAF feature, and disabling GuardDuty destroys findings|21-security]]  
✗ "Disable GuardDuty" — findings and configuration are lost permanently, and disabling is per Region

**"store thousands of plain configuration values / licence keys as cheaply as possible"**  
→ **SSM Parameter Store (Standard tier is free)** [[21-security#⚠️ Traps — why the wrong answer looks right|21-security]]  
✗ Secrets Manager — its per-secret monthly fee is what the cost-flavoured stem is pushing you away from

**"the Lambda / cross-account role has kms:Decrypt in its IAM policy and still cannot decrypt the SSE-KMS object"**  
→ **The key policy must allow it too — and the principal to name is the Lambda execution role ARN** [[21-security#Key facts, limits & pricing|21-security]]  
✗ "Add kms:Decrypt to the IAM policy" offered as the whole fix; KMS allow is two-sided (a deny from IAM alone is enough, an allow is not)

**"the regulator requires FIPS 140-3 Level 3 validated HSMs"**  
→ **KMS already satisfies it — its own HSMs are Level 3 validated in every KMS Region** [[21-security#CloudHSM vs KMS|21-security]]  
✗ CloudHSM — reach for it only on "single-tenant / dedicated hardware", "AWS must have no access to the key material", or a regulator naming the HSM itself

**"the Shield Advanced bill is $3,000 for each of our many accounts"**  
→ **Some accounts sit outside the consolidated-billing family — one subscription covers all subscribed accounts in one family** [[21-security#Key facts, limits & pricing|21-security]]  
✗ Blaming the protection level or the number of protected resources

**"the TLS certificate is for a CloudFront distribution"**  
→ **Request/import it in us-east-1, whatever Region the origin is in** [[21-security#ACM — where the certificate has to live|21-security]]  
✗ "Request the certificate in the same Region as the ALB / the bucket" — and the mirror distractor, a us-east-1 certificate attached to a regional ALB

**"there is no record of the encryption key's usage in CloudTrail" / "what does the service encrypt with by default?"**  
→ **An AWS owned key — usage is not viewable by the customer, so nothing appears in CloudTrail** [[21-security#KMS key types|21-security]]  
✗ AWS managed keys — they are auditable in CloudTrail, so choosing them makes the stem's symptom impossible; AWS managed is also a legacy type not created for new services since 2021

**"unpatched software", "CVE", "scan our EC2 instances / container images / Lambda functions for vulnerabilities"**  
→ **Amazon Inspector (continuous, no scan to schedule)** [[21-security#Which detection service|21-security]]  
✗ GuardDuty — behaviour from logs, not package versions; and options telling you to schedule the scans are wrong since Inspector rescans automatically

**"unusual API calls", "crypto-mining", "an instance is talking to a known malicious IP"**  
→ **GuardDuty — its input is CloudTrail management events, VPC Flow Logs and Route 53 DNS query logs** [[21-security#Which detection service|21-security]]  
✗ Inspector — it reads the software on the host, not the logs of its behaviour

**"we must own and manage the HSM cluster, with an independent audit trail of key material" / "make the key material unavailable instantly"**  
→ **A KMS custom key store backed by a CloudHSM cluster (disconnect it and KMS cannot use the keys)** [[21-security#Key facts, limits & pricing|21-security]]  
✗ A plain customer managed KMS key — it gives you policy control but not a cluster you own, nor the separate CloudHSM audit trail

**"we need the same certificate on an on-premises server / an EC2 host as well"**  
→ **An ACM exportable public certificate — but only if it was issued as exportable (the paid option)** [[21-security#Key facts, limits & pricing|21-security]]  
✗ The stale absolute "an ACM public certificate can never leave AWS"; equally, the free non-exportable certificate you attached to an ALB or CloudFront still cannot be exported

**an account-wide sweep: "what is obviously wasteful or insecure right now" — listed alongside root MFA, public buckets or service quotas. It flags the resource; it does not size it**  
→ **Trusted Advisor — it inspects what is actually deployed, across six categories** [[25-well-architected#Comparisons|25-well-architected]]  
✗ Compute Optimizer — it returns a specific instance type for one workload; Trusted Advisor only flags resources, across six fixed check categories

**rotate an APPLICATION (non-master) credential, or a non-RDS secret, automatically**  
→ **Secrets Manager** [[21-security#⚠️ Traps — why the wrong answer looks right|21-security]]  
✗ Parameter Store SecureString — that is KMS encryption of a value, not rotation; Parameter Store has no rotation at all

**scenario needs the full Trusted Advisor check set, the Trusted Advisor API, or EventBridge-driven automation**  
→ **A higher support plan is implicitly required — "upgrade the support plan" can be the correct answer** [[25-well-architected#Traps|25-well-architected]]  
✗ Assuming "paid plan" is the axis — Developer Support is paid and still does not get the full set; Basic and Developer get all Service Limits checks plus a fixed handful (MFA on root, S3 bucket permissions, public EBS/RDS snapshots, specific ports unrestricted, STS global endpoint)


## Serverless  ·  7

**"unpredictable" or "sudden spike" in table traffic, with throttling to avoid**  
→ **DynamoDB on-demand capacity mode** [[19-serverless#Key facts, limits & pricing|19-serverless]]  
✗ Provisioned capacity with auto scaling — it only reacts after a CloudWatch alarm fires (minutes), so the spike throttles in the meantime; provisioned is the answer for steady, forecastable traffic

**"we need to query an existing DynamoDB table by a new attribute"**  
→ **Add a Global Secondary Index (any time), accepting eventually consistent reads from it** [[19-serverless#Global secondary index vs local secondary index|19-serverless]]  
✗ A Local Secondary Index — it can only be created with the table and can never be added or removed; LSI is the answer only when the stem wants a strongly consistent index read on the same partition key

**a VPC-attached Lambda needs to reach the internet / a third-party API**  
→ **Private subnet routed to a NAT gateway, or VPC endpoints for the specific services** [[19-serverless#⚠️ Traps — why the wrong answer looks right|19-serverless]]  
✗ Moving the function to a public subnet — a Lambda ENI never gets a public IP, so this changes nothing

**an SQS-triggered Lambda keeps failing — where does the message go and how many times is it tried?**  
→ **The queue's rules govern: visibility timeout and maxReceiveCount, then the queue's DLQ (SQS is an event source mapping — Lambda polls it)** [[19-serverless#⚠️ Traps — why the wrong answer looks right|19-serverless]]  
✗ "Lambda retries twice then uses a DLQ" — that is the asynchronous model (S3, SNS, EventBridge), not SQS

**Lambda scales up and the relational database starts refusing connections (max_connections exhausted) while the function looks healthy**  
→ **RDS Proxy — a managed connection pool in front of RDS/Aurora** [[19-serverless#Key facts, limits & pricing|19-serverless]]  
✗ Reserved concurrency — it caps the blast radius but throttles your own function, so it is the mitigation, not the fix

**the API needs response caching, API keys / usage plans, AWS WAF, a private VPC-only endpoint, or request validation**  
→ **API Gateway REST API** [[19-serverless#19 – Serverless (Lambda, DynamoDB, API Gateway)|19-serverless]]  
✗ HTTP API — cheaper and lower latency, and the default instinct, but it has none of those; its own giveaway is the native JWT authorizer

**the job takes longer than 15 minutes**  
→ **Not Lambda — Fargate, AWS Batch, or Step Functions** [[19-serverless#19 – Serverless (Lambda, DynamoDB, API Gateway)|19-serverless]]  
✗ Lambda with a raised timeout — 900 s is the ceiling for an ordinary function; this is the single most common elimination in the topic


## Storage — S3  ·  35

**a named cross-account grant in a bucket policy suddenly stops working**  
→ **One "Principal": "*" statement makes the whole policy public, and RestrictPublicBuckets then strips the named grants too** [[09-s3-security#Worked examples|09-s3-security]]  
✗ Debugging the partner account's IAM policy first — read the whole bucket policy for a public statement before that

**a technically valid bucket policy grants public read, yet objects are still not publicly readable**  
→ **Block Public Access is on and overrides the policy** [[09-s3-security#Worked examples|09-s3-security]]  
✗ Assuming the policy wins because permissions are granted by policy — BPA is a guardrail, not a permission, so the public policy is simply inert

**access pattern is unknown / unpredictable / changing, minimise cost without analysis**  
→ **S3 Intelligent-Tiering** [[09-s3-intro#Why moving data to a cheaper class can cost you more|09-s3-intro]]  
✗ Standard-IA — tempting as 'the next cheapest tier', but the note says Intelligent-Tiering is chosen by access pattern, not as a rung on the price ladder; picking it for known-hot data makes the bill worse

**an object in a WORM/Object Lock bucket 'disappeared' and the delete call returned 200 OK**  
→ **A simple DELETE (no version id) added a delete marker; the locked version is intact underneath** [[09-s3-security#Object Lock (WORM) — verified 2026-08|09-s3-security]]  
✗ Concluding the lock failed — a DELETE naming the protected version id returns 403 AccessDenied, which is the lock working

**application gets 503 Slow Down errors as its S3 request rate ramps up**  
→ **Retry with exponential backoff — the scale-up is gradual, not instantaneous** [[09-s3-advanced#Key facts, limits & pricing|09-s3-advanced]]  
✗ Spreading keys over more prefixes or more buckets — that is the answer to a sustained rate ceiling, not to 503s during ramp-up

**archived data that must still be retrieved in milliseconds when asked for**  
→ **S3 Glacier Instant Retrieval** [[09-s3-intro#Worked examples|09-s3-intro]]  
✗ Glacier Flexible Retrieval — the word 'Glacier' reads as slow, but Flexible needs a restore job (minutes–hours) and Instant does not

**archived object needed back within minutes**  
→ **Glacier Flexible Retrieval with an Expedited retrieval (1–5 min)** [[09-s3-advanced#Glacier retrieval tiers|09-s3-advanced]]  
✗ Glacier Deep Archive — Expedited is not available there at all; its fastest option is Standard at ~12 hours

**backfill objects that currently sit in Glacier Deep Archive to a replication destination**  
→ **Restore them and copy them to another storage class first — Batch Replication cannot handle archived objects** [[09-s3-advanced#Worked examples|09-s3-advanced]]  
✗ Running Batch Replication directly — it is the right tool for pre-existing objects, but not for ones in the Glacier or Intelligent-Tiering archive tiers

**bucket A replicates to B and B replicates to C — will A's objects reach C?**  
→ **No. Replication is not chained; a replica can only be re-replicated with Batch Replication** [[09-s3-advanced#Worked examples|09-s3-advanced]]  
✗ Assuming the chain works because both rules are valid — each rule is fine, but a live rule will not re-replicate a replica

**bucket delete fails with BucketNotEmpty although the bucket appears empty**  
→ **Versioning is on — every object version and every delete marker must be purged first** [[09-s3-intro#Versioning, delete markers, and the bill that grows in the dark|09-s3-intro]]  
✗ Deleting the objects again — a plain delete only adds another delete marker, so the bucket stays non-empty

**default encryption has just been turned on — what happens to the objects already in the bucket?**  
→ **Nothing; rewrite them with S3 Batch Operations → Copy** [[09-s3-security#Worked examples|09-s3-security]]  
✗ Assuming default encryption re-encrypts in place — it is a rule applied at write time only

**each file must be encrypted with a different key, without the overhead of splitting the data into logical groups**  
→ **Plain SSE-S3 — it already encrypts every object under its own unique key** [[09-s3-security#Which encryption options actually exist — per service|09-s3-security]]  
✗ SSE-KMS with per-object encryption context, or separate buckets per logical group — both are the over-built answer to uniqueness S3 already provides

**high-throughput SSE-KMS workload, KMS request charges too high, must keep the audit trail**  
→ **Enable S3 Bucket Keys (objects stay SSE-KMS)** [[09-s3-security#Which encryption options actually exist — per service|09-s3-security]]  
✗ Switching to SSE-S3 or SSE-C — also cheaper, but it abandons the key policy and CloudTrail trail that made SSE-KMS the requirement

**how long can a presigned URL be valid for?**  
→ **7 days (604800s) via CLI/SDK; 12 hours via the console** [[09-s3-security#Presigned URLs|09-s3-security]]  
✗ Quoting one number — the console ceiling is 12 hours, so a stem that says 'generated in the console' caps at 12h not 7 days

**immutable, nobody may delete it, not even us — and the protected things are S3 OBJECT VERSIONS**  
→ **Object Lock in COMPLIANCE mode** [[09-s3-security#Object Lock (WORM) — verified 2026-08|09-s3-security]]  
✗ GOVERNANCE mode — identical mechanics, but anyone with s3:BypassGovernanceRetention plus the bypass header can delete, so it fails a 'not even root' requirement

**infrequently accessed data that could be regenerated (thumbnails, derived files, a secondary copy), cheapest option**  
→ **S3 One Zone-IA** [[09-s3-intro#Worked examples|09-s3-intro]]  
✗ Standard-IA — correct for an only copy, but ~20% more expensive; One Zone-IA loses only when the data cannot be re-created

**millions of very small objects (a few KB each), asked to cut storage cost**  
→ **Leave them in S3 Standard — a cheaper class can cost more because of the 128 KB minimum billable size** [[09-s3-intro#Why moving data to a cheaper class can cost you more|09-s3-intro]]  
✗ Standard-IA / One Zone-IA — the per-GB rate is lower, but each object is billed as at least 128 KB, so tiny objects cost multiples of their real size

**must be notified when a lifecycle rule expires or transitions objects**  
→ **The s3:LifecycleExpiration / s3:LifecycleTransition event types** [[09-s3-advanced#Events & automation|09-s3-advanced]]  
✗ s3:ObjectRemoved:* — it does not fire for automatic lifecycle deletes, so a pipeline built on it silently misses them

**must have an audit trail of who used the encryption key, or a key policy, or cross-account access to encrypted data**  
→ **SSE-KMS with a customer managed key** [[09-s3-security#Which encryption options actually exist — per service|09-s3-security]]  
✗ SSE-S3 — it encrypts everything but gives no key policy and no per-use trail of the key

**must survive the complete loss of an Availability Zone**  
→ **A storage class stored in ≥3 AZs (Standard / Standard-IA / Glacier), not a One Zone class** [[09-s3-intro#Durability and availability are two different numbers|09-s3-intro]]  
✗ One Zone-IA — it is advertised at the same 11 nines, so the durability number looks sufficient; the note says the eleven-nines figure does not cover AZ loss for One Zone classes

**needs sustained read rates above ~5,500 GET/s against the data**  
→ **Spread the keys across more prefixes inside the one bucket (3,500 writes / 5,500 reads per prefix, unlimited prefixes)** [[09-s3-advanced#Key facts, limits & pricing|09-s3-advanced]]  
✗ Splitting the data across several buckets, or moving to EFS — the limit is per prefix, not per bucket

**notifications never arrive / enabling the notification fails immediately with a permissions error**  
→ **Add a resource policy on the SQS queue or SNS topic allowing the S3 service principal, scoped with aws:SourceArn and aws:SourceAccount** [[09-s3-advanced#Events, and the two ways they fail|09-s3-advanced]]  
✗ Fixing the bucket policy or giving S3 an IAM role — the permission has to live on the destination resource, not on the bucket

**object is tagged after upload and a tag-based replication rule should pick it up**  
→ **It will not — run S3 Batch Replication** [[09-s3-advanced#Replication|09-s3-advanced]]  
✗ Assuming the live tag-based rule catches up — the tag must be in the PutObject call itself

**objects must be moved to a cheaper class immediately on upload / 'can a lifecycle rule transition on day 0?'**  
→ **Yes — the 30/90/180-day minimums are billing floors, not waiting periods; a rule can transition at day 0** [[09-s3-intro#Why moving data to a cheaper class can cost you more|09-s3-intro]]  
✗ 'you must wait 30 days before transitioning to Standard-IA' — the minimum storage duration is read as a waiting period; what it really constrains is chained transitions

**one bucket shared by many teams, each needing its own permissions / bucket policy hitting the 20 KB limit**  
→ **S3 Access Points — a named endpoint per team, each with its own policy and optional VPC restriction** [[09-s3-security#Two policies pointing at each other|09-s3-security]]  
✗ One large bucket policy — it hits the 20 KB ceiling and becomes unreviewable; note an access point can only narrow, never grant what the bucket withholds

**one very large object transferred across a long distance, as fast as possible**  
→ **S3 Transfer Acceleration (nearest edge entry, then an optimized network path to the bucket's Region)** [[09-s3-advanced#Worked examples|09-s3-advanced]]  
✗ CloudFront — it caches, which wins for the same objects read repeatedly by many viewers; a single long-distance transfer gets nothing from a cache

**partner account is granted s3:GetObject in the bucket policy and still gets AccessDenied**  
→ **Cross-account needs both sides — their IAM policy must also allow the call** [[09-s3-security#Worked examples|09-s3-security]]  
✗ Widening the bucket policy further — the missing half lives in an account you do not control

**replication is enabled but the destination is missing the data that was already in the bucket**  
→ **S3 Batch Replication (an on-demand job) to backfill** [[09-s3-advanced#Replication starts from now, not from the beginning|09-s3-advanced]]  
✗ Re-enabling or re-creating the live CRR/SRR rule — a live rule only ever copies objects created or updated after it existed

**require MFA before a version can be permanently deleted or versioning turned off**  
→ **MFA Delete — enabled only by the bucket-owning root account with an MFA device, via the CLI or the API/SDKs** [[09-s3-security#MFA Delete|09-s3-security]]  
✗ 'CLI only' / an IAM admin doing it in the console — the console cannot do it at all, but an API/SDK option is valid, so don't reject an answer that says PutBucketVersioning

**Route 53 alias record pointing a custom domain at the S3 website endpoint**  
→ **The bucket must be named exactly after the domain (plus a second www bucket configured as a redirect)** [[09-s3-intro#Key facts, limits & pricing|09-s3-intro]]  
✗ Any bucket name you like — true only once CloudFront is the origin-facing layer; it is false for the website-endpoint pattern

**static website must be served over HTTPS / with a custom TLS certificate**  
→ **CloudFront in front of the bucket (which also lets the bucket go private behind OAC)** [[09-s3-intro#Key facts, limits & pricing|09-s3-intro]]  
✗ The S3 static-website endpoint on its own — it is HTTP-only, so no amount of bucket configuration gives you HTTPS

**storage charges exceed the visible data AND large uploads fail or are retried; nothing extra appears in list-object-versions either**  
→ **Incomplete multipart uploads — add the lifecycle action that deletes incomplete multipart uploads** [[09-s3-advanced#Worked examples|09-s3-advanced]]  
✗ Noncurrent versions — also an invisible cost, but those show up in list-object-versions; incomplete parts appear in no ordinary listing at all

**temporary access to one private object served DIRECTLY FROM S3**  
→ **A presigned URL, which carries the permissions of whoever generated it** [[09-s3-security#Worked examples|09-s3-security]]  
✗ Creating an IAM user for them, or making the bucket public — the first builds a permanent identity for a one-off, the second exposes everything

**versioning is enabled and objects are overwritten repeatedly; the bill grows although the console shows the bucket is the same size**  
→ **Noncurrent versions accumulating — add a lifecycle rule that expires noncurrent versions** [[09-s3-intro#Versioning, delete markers, and the bill that grows in the dark|09-s3-intro]]  
✗ Suspending or 'disabling' versioning — it stops new versions but leaves (and keeps billing) every existing one; versioning can be suspended but never disabled

**WORM protection wanted, but a named admin group must keep an emergency override**  
→ **Object Lock in GOVERNANCE mode plus s3:BypassGovernanceRetention and the x-amz-bypass-governance-retention header** [[09-s3-security#Object Lock (WORM) — verified 2026-08|09-s3-security]]  
✗ COMPLIANCE mode — there is no override at all; AWS's only documented escape before expiry is closing the account


## Storage — other  ·  14

**an EFS file that moved to IA is accessed again — does it return to Standard?**  
→ **No, not by default; you must set the Transition into Standard policy to on-first-access** [[12-storage-extras#Key facts, limits & pricing|12-storage-extras]]  
✗ Assuming automatic promotion like a cache — the default is None, and unlike Glacier there is no restore job either

**Auto Scaling instances across several AZs must all see the same uploaded files**  
→ **EFS, with a mount target in each AZ the ASG spans** [[12-storage-extras#Worked examples|12-storage-extras]]  
✗ One shared EBS volume — an EBS volume lives in a single AZ and attaches to one instance, so it cannot back an ASG spanning AZs

**centrally managed backups copied into a different AWS account**  
→ **AWS Backup cross-account copy — which requires an AWS Organizations structure** [[12-storage-extras#AWS Backup: one place instead of six|12-storage-extras]]  
✗ Cross-Region copy — the answer when the requirement is distance from production, not account isolation; only cross-account pulls in Organizations

**existing backup software must keep writing to tape, unchanged**  
→ **Tape Gateway (a virtual tape library)** [[12-storage-extras#Traps|12-storage-extras]]  
✗ DataSync — it transfers data and the job ends; the backup software needs a permanent local interface, which is what a gateway is

**HPC / ML training needs sub-millisecond POSIX access to a dataset that lives in S3**  
→ **FSx for Lustre linked to the S3 bucket** [[12-storage-extras#FSx: when the workload demands a *specific* file system|12-storage-extras]]  
✗ EFS — a shared Linux file system, but it is not the speed/S3-backed-compute answer and has no S3 linkage

**immutable, nobody may delete it, not even us — and the protected things are RECOVERY POINTS IN A BACKUP VAULT**  
→ **AWS Backup Vault Lock in compliance mode** [[12-storage-extras#AWS Backup: one place instead of six|12-storage-extras]]  
✗ Governance mode — it can be unlocked by anyone holding the IAM permission, so it fails an 'immutable even to us' requirement

**low-latency block storage over iSCSI, with Multi-AZ high availability**  
→ **FSx for NetApp ONTAP — the only FSx flavour offering block over iSCSI** [[12-storage-extras#FSx: when the workload demands a *specific* file system|12-storage-extras]]  
✗ FSx for Windows File Server — the default 'lift-and-shift Windows' pick, but it is SMB file storage and offers no iSCSI block

**low-latency on-premises access to the entire dataset, plus offsite backups**  
→ **Volume Gateway — stored volumes (all data local, snapshots to S3)** [[12-storage-extras#Storage Gateway: making cloud storage look local|12-storage-extras]]  
✗ Cached volumes — only a hot subset is local, so 'the entire dataset at low latency' fails

**Lustre results must survive a file server failure / long-running job whose output can't be re-created**  
→ **Persistent deployment type (replicated, failed servers replaced)** [[12-storage-extras#Traps|12-storage-extras]]  
✗ Scratch — read as the 'cheaper and faster' choice, but the axis is durability: scratch is not replicated and the data does not survive a file server failure

**migrate or sync on-premises NFS/SMB data to AWS on a schedule, with integrity validation**  
→ **AWS DataSync** [[12-storage-extras#Traps|12-storage-extras]]  
✗ Storage Gateway — also network-based and also needs something installed locally, but it is a permanent bridge the on-prem system keeps using, not a transfer job

**one file system serving both Windows (SMB) and Linux (NFS) clients the same data**  
→ **FSx for NetApp ONTAP — the multi-protocol one** [[12-storage-extras#FSx: when the workload demands a *specific* file system|12-storage-extras]]  
✗ FSx for Windows File Server — Linux clients can speak SMB to it, but only ONTAP is the documented multi-protocol (NFS, SMB, iSCSI, NVMe) answer

**process or filter the data where it is collected, before or instead of shipping it**  
→ **Snowball Edge Compute Optimized** [[12-storage-extras#Which Snow device — storage volume, or compute at the edge?|12-storage-extras]]  
✗ Snowball Edge Storage Optimized — the bigger device (210 TB vs 28 TB), so 'more capability' reads as the right answer; Compute Optimized is the configuration AWS designates for compute

**stop the on-premises storage footprint from growing, keep hot data local**  
→ **Volume Gateway — cached volumes (primary copy in S3)** [[12-storage-extras#Traps|12-storage-extras]]  
✗ Stored volumes — the names are nearly interchangeable; anchor on which copy is authoritative, and 'reduce on-prem storage' means the primary must live in S3

**Windows EC2 instances need a shared file system, with Active Directory users and Windows ACLs**  
→ **FSx for Windows File Server (SMB + AD + Windows ACLs)** [[12-storage-extras#Traps|12-storage-extras]]  
✗ EFS — 'shared file system' fits perfectly in words, but AWS does not support EFS with Windows EC2 instances, so it is an automatic elimination


## Streaming & analytics  ·  17

**"all events for a given customer/device must be processed in the order they arrived"**  
→ **Give all of that entity's records the same partition key — order is per shard** [[16-kinesis#Traps|16-kinesis]]  
✗ Assuming the stream is globally ordered; two records with different partition keys have no defined relative order. Same mechanic as MessageGroupId in FIFO SQS.

**"build a central data repository and import from our RDS databases, bulk then incremental" / "column-level permissions on the data lake"**  
→ **AWS Lake Formation** [[22-analytics#Key facts, limits & pricing|22-analytics]]  
✗ "Just put it in S3" or hand-written bucket policies — Lake Formation is the authorization layer over the Glue Data Catalog and it ingests, which is the half most people miss.

**"define the schema once so several query engines can use it" / "discover the schema automatically"**  
→ **One Glue Crawler into one Glue Data Catalog — shared by Athena, EMR and Redshift Spectrum** [[22-analytics#Traps|22-analytics]]  
✗ Options that define schemas per engine or sync metadata between them; that is work AWS already did.

**"full-text search / relevance ranking", "Kibana or OpenSearch Dashboards", "live dashboard of application logs", "real-time monitoring"**  
→ **Amazon OpenSearch Service** [[22-analytics#Traps|22-analytics]]  
✗ Athena — it is SQL aggregates over historical logs already in S3, with nothing running between queries. "Query last quarter's logs with SQL, no infrastructure" flips the answer back to Athena.

**"genuinely sub-second, per-record reaction to each event"**  
→ **Kinesis Data Streams with a consumer (enhanced fan-out if latency really matters)** [[16-kinesis#Traps|16-kinesis]]  
✗ Firehose — but be careful why: its buffering interval can be set to 0 seconds ("zero buffering", delivery within a few seconds), so do not eliminate Firehose on latency alone unless the stem demands sub-second per-record handling.

**"join years of cold history in S3 to the hot tables already in the warehouse, in one query"**  
→ **Redshift Spectrum (external schemas/tables over the data catalog)** [[22-analytics#Which engine does the exam mean?|22-analytics]]  
✗ Loading the history into the cluster (expensive, and it was the thing you wanted to avoid) or plain Athena (no warehouse tables to join against).

**"multiple consumers each need full throughput" / "the consumers are starving each other"**  
→ **Enhanced fan-out (own 2 MB/sec per shard per registered consumer, pushed via SubscribeToShard)** [[16-kinesis#Traps|16-kinesis]]  
✗ Adding shards — the default shared fan-out splits one shard's 2 MB/sec across every consumer, so more shards does not stop them competing.

**"no code to write" / "just land the streaming data in S3, Redshift, OpenSearch or Splunk"**  
→ **Amazon Data Firehose** [[16-kinesis#Data Streams vs Firehose|16-kinesis]]  
✗ Kinesis Data Streams — you would have to write and operate the consumer; the stem explicitly asked for nothing to manage.

**"ProvisionedThroughputExceededException at well below the stream's nominal capacity, and adding shards didn't help"**  
→ **Low-cardinality partition key → hot shard; switch to a high-cardinality key (e.g. device_id)** [[16-kinesis#Traps|16-kinesis]]  
✗ Adding shards or raising the shard count — the key still produces only a handful of hash values, so the new shards stay idle.

**"reduce our Athena costs" / "the queries scan too much data"**  
→ **Parquet/ORC + compression + partitioning (plus workgroup scan limits as a guardrail)** [[22-analytics#Which engine does the exam mean?|22-analytics]]  
✗ Any option that resizes something — Athena is serverless and billed on bytes scanned, so there is nothing to make bigger. One caveat: Athena Capacity Reservations ($0.30/DPU-hour) are a real feature, so do not reject an option merely for naming provisioned capacity.

**"run Spark jobs over S3 with the least operational overhead"**  
→ **AWS Glue (Spark-based serverless ETL engine)** [[22-analytics#What problem does this solve?|22-analytics]]  
✗ EMR — "Spark" does not automatically mean EMR. EMR wins when the stem wants the wider Hadoop ecosystem, cluster-level control, or Spot economics; it loses on "least operational overhead".

**"the data must be re-readable / consumed again later by another application"**  
→ **Kinesis Data Streams (24 h – 365 days retention, re-readable)** [[16-kinesis#Traps|16-kinesis]]  
✗ Firehose — it holds undelivered data up to 24 hours while retrying, so it is not literally "no retention", but there is nothing you can read back out of it.

**"the Redshift warehouse must survive the loss of an entire Region"**  
→ **Enable cross-Region snapshot copy on the cluster (one destination Region at a time; copies get their own 7-day default retention; KMS clusters need a snapshot copy grant in the destination Region)** [[22-analytics#Key facts, limits & pricing|22-analytics]]  
✗ Automated snapshots alone (they stay in the source Region) or a scheduled job you build — the copy is a cluster configuration, not custom automation.

**"the streaming consumer's IAM role needs DynamoDB permissions" / "unexplained DynamoDB tables appeared"**  
→ **The Kinesis Client Library stores consumption state in DynamoDB — three tables per application** [[16-kinesis#Key facts, limits & pricing|16-kinesis]]  
✗ Assuming a Kinesis consumer touches only Kinesis; the DynamoDB dependency is a real IAM requirement, not a distractor.

**"use Spot Instances to cut the EMR bill"**  
→ **Spot for task nodes only; On-Demand for primary and core** [[22-analytics#Traps|22-analytics]]  
✗ "Spot for all nodes" — core nodes hold HDFS data so an interruption can lose data, and losing the primary kills the cluster.

**"we already run Kafka" / "must keep our Kafka APIs, tooling and expertise"**  
→ **Amazon MSK (MSK Serverless if capacity planning is also to go)** [[22-analytics#Kinesis vs MSK|22-analytics]]  
✗ Kinesis Data Streams — the API is AWS-proprietary, so existing Kafka applications would be rewritten. Greenfield-on-AWS with least overhead flips it back to Kinesis.

**several teams must each process the same events independently, needing a position in a RETAINED LOG: replay, reprocess history, each at its own offset**  
→ **Kinesis Data Streams (shared log, per-consumer position, replay within retention)** [[16-kinesis#Traps|16-kinesis]]  
✗ SQS deletes a message once processed, so a second consumer never sees it. SNS is the sharper distractor: a FIFO topic with an archive policy can replay, so "replay" alone does not kill it — what kills it is many independent consumers each at its own position.

