---
topic: 21-security
domain: secure
status: reviewed
services: [KMS, CloudHSM, SecretsManager, ParameterStore, ACM, GuardDuty, Inspector, Macie, SecurityHub, SecurityLake, Artifact, Shield, WAF, FirewallManager, Detective]
related: [01-iam, 01-iam-advanced, 09-s3-security, 11-cloudfront, 20-monitoring]
tags: [topic, domain/secure]
---

# 21 – Security & Encryption
Keys, secrets, and a shelf of detection services whose only exam question is "which one".

> [!info] Exam TL;DR
> - **KMS encrypts up to 4,096 bytes directly.** Anything bigger uses **envelope encryption**: `GenerateDataKey` returns a plaintext data key *and* an encrypted copy; you encrypt the data locally and store the encrypted key beside it.
> - **Automatic rotation is yearly by default and now configurable** (`RotationPeriodInDays`, default **365**). **AWS managed keys rotate every year** — that changed from three years in May 2022, so older courses say 1,095 days.
> - **Rotation does not re-encrypt your data**, does not rotate data keys, and does not change the key ID. Old key material is retained so old ciphertext still decrypts.
> - **Only symmetric KMS-generated keys auto-rotate.** Asymmetric, HMAC and custom-key-store keys must be rotated **manually**.
> - **Secrets Manager rotates; Parameter Store does not.** Parameter Store Standard is **free, 4 KB, 10,000 params**; Advanced is **paid, 8 KB, 100,000, supports policies** — and you can upgrade but **never downgrade**.
> - **Detection services, one line each:** GuardDuty = threats from **logs**; Inspector = **vulnerabilities** in EC2/ECR/Lambda; Macie = **sensitive data in S3**; Security Hub = **aggregates** everyone's findings; Detective = **investigate** a finding's root cause.
> - **Shield Standard is free and automatic (L3/L4). Shield Advanced is $3,000/month with a 1-year commitment.**
> - **WAF attaches to ALB, API Gateway REST, AppSync, Cognito user pool, App Runner, Amplify, Verified Access — and CloudFront ([[11-cloudfront]]). Never to an NLB or an EC2 instance.**

## What problem does this solve?

Two separate jobs share this section, and it's worth keeping them apart.

**Encryption and secrets** is about controlling access to *data and credentials* — who can decrypt this, where does the database password live, how does it get rotated. KMS is the root of nearly all of it: almost every "encrypt at rest" checkbox in AWS is a KMS key under the hood.

**The detection shelf** — GuardDuty, Inspector, Macie, Security Hub, Detective — is about *noticing* that something is wrong. They sound interchangeable and the exam tests exactly one thing about them: which one to reach for. Each has a different input.

The genuinely important idea in the first half is **envelope encryption**, because it explains a limit that otherwise looks arbitrary. KMS will only encrypt 4 KB directly. That isn't a quota to memorise for its own sake — it's the reason every AWS service that encrypts large objects works the way it does: get a data key from KMS, encrypt the data yourself with it, throw away the plaintext key, keep the encrypted one. KMS never sees your data.

> In one line: KMS protects keys, not data — you encrypt data with a data key, and KMS protects that.

## How it actually works

**KMS key types.** *Customer managed* — you create it, you own the key policy (a resource-based policy, evaluated alongside IAM exactly as [[01-iam]] describes), you choose rotation, and it carries a monthly fee plus per-request charges (~$1/month per key — check current pricing). *AWS managed* (`aws/s3`, `aws/rds`) — created for you, free, rotated yearly, and **you cannot change its policy**. *AWS owned* — entirely inside the service, invisible to you.

**AWS managed keys are legacy.** This is the sentence that settles a whole family of
questions: *"AWS managed keys are a legacy key type that is **no longer being created for new
AWS services as of 2021**. Instead, new (and legacy) AWS services are using what's known as an
**AWS owned key** to encrypt customer data by default."* So when a stem asks what a service
encrypts with **by default**, the modern answer is **AWS owned**, not AWS managed — and
because AWS owned key usage is *"not viewable by the customer"*, **nothing appears in
CloudTrail**. Those two facts travel together and are asked together.

Default encryption by service, where it gets tested:

| Service | Default key | Notes |
|---|---|---|
| **DynamoDB** | **AWS owned** | *"Default encryption type."* All data is **always** encrypted — there is no off switch. You may switch to AWS managed or customer managed at any time. |
| **DAX cluster** (encryption at rest) | **AWS managed** | the exception sitting right next to DynamoDB |
| **S3** | **SSE-S3** (AES256) since Jan 2023 | see [[09-s3-security]] |
| **EBS, RDS, EFS** | AWS managed (`aws/ebs`, `aws/rds`…) when you tick "encrypt" | these predate the 2021 change |

That "cannot change its policy" line is the practical discriminator: the moment a stem mentions cross-account access to encrypted data, or controlling exactly who may decrypt, the answer is a **customer managed key**. (A bare *audit trail of key use* doesn't decide it — AWS managed keys are logged in CloudTrail too; only AWS owned keys aren't.)

**Envelope encryption, concretely.** `GenerateDataKey` returns two things — a plaintext data key and the same key encrypted under your KMS key. You encrypt your object locally with the plaintext key, discard it from memory, and store the encrypted copy alongside the ciphertext. To read it back, you send the encrypted key to KMS's `Decrypt`, get the plaintext key back, and decrypt locally. Your data never crosses the KMS API.

> In one line: KMS's 4 KB limit is not a restriction, it is the design — KMS encrypts keys, and keys are small.

**Rotation, as it now works.** Enable automatic rotation and AWS generates new key material on a schedule — **365 days by default, and you may set a different period**. There is also **on-demand rotation** (max 25 per key, not adjustable). Crucially, *"Key rotation has no effect on the data that the KMS key protects. It does not rotate the data keys that the KMS key generated or re-encrypt any data."* Old material is kept; AWS picks the right version to decrypt automatically. The key ID never changes.

**Secrets Manager vs Parameter Store.** Both store configuration; only Secrets Manager rotates. Secrets Manager costs per secret per month; Parameter Store Standard is free. Use Parameter Store for a config value, Secrets Manager for a credential that must rotate — and remember that RDS can create and rotate its own master password in Secrets Manager with no Lambda at all.

**The detection shelf** differs by *input*, which is the cleanest way to hold them:

| Service | Reads | Finds |
|---|---|---|
| GuardDuty | foundational: CloudTrail management events, VPC Flow Logs, Route 53 DNS query logs; plus CloudTrail **S3 data events** with the **S3 Protection** plan | threat activity |
| Inspector | EC2 instances, ECR images, Lambda functions | software CVEs, network exposure |
| Macie | S3 objects | sensitive data / PII |
| Security Hub | the other services' findings | a single prioritised view |
| Detective | the same logs, as a graph | the root cause of one finding |

> In one line: GuardDuty watches logs, Inspector watches software, Macie watches data, Security Hub aggregates, Detective investigates.

## Architecture diagram

```mermaid
graph TB
  subgraph Keys
    K[KMS key] -->|GenerateDataKey| DK[plaintext data key + encrypted copy]
    DK --> APP[your app encrypts locally]
    APP --> OBJ[(ciphertext + encrypted data key)]
  end
  subgraph Secrets
    SM[Secrets Manager · rotates] --- PS[Parameter Store · free, no rotation]
    SM -.encrypted by.-> K
    PS -.SecureString encrypted by.-> K
  end
  subgraph Detection
    GD[GuardDuty · logs] --> SH[Security Hub]
    IN[Inspector · EC2/ECR/Lambda] --> SH
    MA[Macie · S3] --> SH
    SH --> DT[Detective · investigate]
  end
  subgraph Edge
    SHIELD[Shield] --> CF[CloudFront / ALB]
    WAF[WAF web ACL] --> CF
  end
```

## Key facts, limits & pricing

- **The AWS Config managed rule `access-keys-rotated`** (identifier `ACCESS_KEYS_ROTATED`) checks whether **active** IAM access keys have been rotated within **`maxAccessKeyAge`** days — type `int`, **default 90**. A key past that age makes the rule `NON_COMPLIANT`. Three details that discriminate it from neighbours: its trigger type is **Periodic**, not configuration-change (so it evaluates on a schedule, and a brand-new key does not trip it immediately); its resource type is **`AWS::IAM::User`**; and it **does not apply to the account root user's access keys** — root keys need a different control. The remediation pattern then holds as written: Config emits a **`ComplianceChangeNotification`** ("Config Rules Compliance Change") to EventBridge when a resource's compliance type changes, and an EventBridge rule can invoke a Lambda on it to deactivate or delete the key. Same shape as [[20-monitoring]]'s Config-plus-EventBridge remediation.

- **An AWS CloudHSM key store** (the custom key store) is *"a custom key store backed by an AWS CloudHSM cluster"*: KMS *"generates and stores **non-extractable** key material for the KMS key in an AWS CloudHSM cluster **that you own and manage**"*, and cryptographic operations run **in the HSMs in that cluster**. That one design gives all three things a stem usually asks for together — KMS's integrations, **full control** of the cluster, and an **independent audit trail** via the CloudHSM client (*"view, audit, and manage the key material"*). Also: **while the key store is disconnected, KMS cannot access it** and the keys cannot be used — the "make key material unavailable immediately" answer. The cluster needs **at least two active HSMs in different AZs**.
- **Shield Advanced's $3,000/month is charged once per consolidated-billing family:** *"When you subscribe multiple accounts that are in the same AWS Organizations consolidated billing account family, one subscription price covers all subscribed accounts in the family. The organization must own all of the AWS accounts and all of their resources."* So a surprisingly large Shield Advanced bill across many accounts points at **accounts outside the consolidated bill**, each paying its own $3,000 — not at the protection. *(Verified 2026-10-01.)*
- **Export: the old "an ACM public certificate can never leave AWS" rule is gone.** ACM has an
  `ExportCertificate` API (`aws acm export-certificate`) returning the certificate, the chain and a
  **passphrase-encrypted private key**, so a public certificate *can* now be reused on an
  on-premises server or an EC2 host. Two conditions keep the classic exam answer mostly intact:
  the certificate must have been issued as **exportable** (the paid option above), and *"ACM public
  certificates created prior to June 17, 2025 cannot be exported."* A certificate you attached to
  CloudFront or an ALB in the ordinary way is still the free, **non-exportable** kind. *(Verified 2026-10-07.)*
- **A third-party CA certificate can be imported into ACM**, and an imported certificate then behaves like an ACM-issued one with **one** exception that is the whole exam point: **ACM does not provide managed renewal for imported certificates**. You own expiry monitoring and manual reimport. (So "we want certificates to renew automatically" eliminates an imported cert, whatever its CA.)
- **The legacy IAM server-certificate store** is the fallback where ACM is unavailable: use IAM as a certificate manager *"only when you must support HTTPS connections in a Region that is not supported by ACM"*, and *"you cannot manage your certificates from the IAM Console."* Call it **API-only** rather than CLI-only — it is the IAM API (`UploadServerCertificate`), reachable via the CLI **or** Tools for Windows PowerShell. Two edges: IAM can deploy server certificates in **all** Regions but the certificate must come from an **external** provider, and you **cannot** upload an ACM certificate into IAM.

- **WAF geo match rule statement:** manages requests by **country and region of origin**, matching **ISO 3166-1 alpha-2** country codes (`HK`, `DE`…). WAF derives the country from the **request's IP address**, and can be told to read an alternate header such as **`X-Forwarded-For`** via forwarded-IP configuration. It also **adds country/region labels** to every request, match or not, which a later label-match rule can use. *(Verified 2026-10-01.)*
*Verified against AWS docs 2026-09-25.*

- **KMS `Encrypt` maximum plaintext: 4,096 bytes** for `SYMMETRIC_DEFAULT`. (Asymmetric is smaller still — RSA_2048 with OAEP-SHA-256 is 190 bytes.)
- **Deleting a KMS key is scheduled, never immediate.** A mandatory waiting period of **7–30 days** (**default 30**) applies; AWS may extend it by up to 24 hours. Throughout it the key state is **`Pending deletion`**, the key **cannot be used in any cryptographic operation**, and the deletion **can still be cancelled**. When the period ends the key, its aliases and all KMS metadata are destroyed — and anything encrypted under it becomes permanently unrecoverable. *(Verified 2026-09-30.)*
- **KMS allow is two-sided:** *"Without permission from the key policy, IAM policies that allow permissions have no effect."* A **deny** from IAM needs no key-policy permission. The **default key policy enables IAM policies**, so only a hand-tightened key policy exposes the rule. **Key policies are Regional; IAM policies are global.** For a Lambda principal, name the **execution role ARN**. *(Verified 2026-09-30.)*
- **Rotation period:** *"If you do not specify a value for `RotationPeriodInDays`... the default value is 365 days."* **On-demand rotation: maximum 25 per key, and this quota is not adjustable.**
- **AWS managed keys:** *"AWS KMS automatically rotates AWS managed keys every year"* — and *"In May 2022, AWS KMS changed the rotation schedule for AWS managed keys from every three years (approximately 1,095 days) to every year."*
- **Cannot auto-rotate:** asymmetric KMS keys, HMAC KMS keys, keys in custom key stores, and keys with **imported key material** (`EXTERNAL` origin) — AWS: *"Automatic key rotation is supported only on symmetric encryption KMS keys with key material that AWS KMS generates (`AWS_KMS` origin)."* These can't auto-rotate; asymmetric, HMAC and custom-key-store keys are rotated **manually**, while imported (`EXTERNAL`) keys also support **on-demand** rotation. *(Corrected 2026-10-15.)*
- **KMS quotas:** 100,000 customer managed keys per Region, **50 aliases per key**, **50,000 grants per key**, 10 custom key stores.
- **Parameter Store tiers:** Standard — **10,000** parameters, **4 KB**, no policies, no cross-account sharing, **no charge**. Advanced — **100,000**, **8 KB**, policies **supported**, shareable, **charges apply**. *"You can change a standard parameter to an advanced parameter, but you can't change an advanced parameter to a standard parameter."*
- **GuardDuty foundational data sources:** **CloudTrail management events, VPC Flow Logs, Route 53 Resolver DNS query logs** — consumed as independent duplicate streams, so *"You don't need to enable anything else"* **for these foundational sources** and your own flow-log config is unaffected. 30-day free trial. That sentence is scoped to the foundational sources, not to all of GuardDuty: **protection plans** such as **S3 Protection** are a second layer — see the S3 trap below. *(Scope corrected 2026-10-14.)*
- **Amazon Security Lake** is a fully managed **security data lake**: it automatically centralises security **log and event data** from AWS services, SaaS providers, on-premises and third-party sources into **S3 buckets you own**. AWS: *"Security Lake converts ingested data into Apache Parquet format and a standard open-source schema called the Open Cybersecurity Schema Framework (OCSF)."* It works across **accounts and Regions**. A hand-built Glue or Lambda pipeline could do the same job, but it is the **higher-operational-overhead** option. *(Verified 2026-10-14.)*
- **Inspector** scans **EC2 instances, container images in ECR, and Lambda functions** — and AWS now says activation enrols you in *all* scan types, so treat that list as the exam's core rather than a closed set. Scanning is *"continually"* and automatically — *"you don't need to manually schedule or configure assessment scans"* — rescanning when a package changes or a new CVE is published.
- **Macie** analyses **Amazon S3** — bucket inventory, public-access posture, and sensitive-data discovery using **managed** and **custom data identifiers**. 30-day free trial.
- **Shield Standard:** protection *"for all AWS customers... at no additional charge"* (network/transport layer). **Shield Advanced: $3,000/month, 1-year commitment**, and it includes *"certain AWS WAF usage for Shield protected resources at no additional cost for up to **50 billion AWS WAF requests per month**"* — covered, but not uncapped.
- **WAF web ACL targets:** regional — **API Gateway REST API, Application Load Balancer, AppSync GraphQL API, Cognito user pool, App Runner, Bedrock AgentCore Gateway, Verified Access, Amplify**; global — **CloudFront**, whose web ACL *"will have a hard-coded Region of US East (N. Virginia)"*. One web ACL per resource; a CloudFront web ACL cannot also be attached to a regional resource.
- **WAF IP set match:** *"The IP set match statement inspects the IP address of a web request against a set of IP addresses and address ranges"*; *"An IP set can hold up to 10,000 IP addresses or IP address ranges to check."* Put it in a web ACL on CloudFront to allow-list IPs at the edge. **Security groups and NACLs can't do this for CloudFront**: SGs attach to resources in a VPC and NACLs to subnets, and a distribution is neither. *(Verified 2026-10-15.)*
- **DDoS resiliency, AWS's way:** use edge services — *"such as Amazon CloudFront, AWS Global Accelerator, and Amazon Route 53"* — with WAF and Shield; keep anything users don't need off the internet (*"make sure that those resources aren't accessible from the internet"*); scale with Auto Scaling or serverless. **Dedicated Instances** (tenancy) and **EFA** (HPC networking) are not DDoS measures. *(Verified 2026-10-15.)*

## Comparisons

### KMS is the exception to the resource-policy rule

Everywhere else in IAM, *within one account*, an identity policy and a resource policy **widen**
each other: either one allowing is enough. A **cross-account** request needs **both** to allow
([[01-iam-advanced]])
([[01-iam-advanced]]). **A KMS key policy does not work that way**, and it is the one carve-out
worth memorising. AWS's wording:

> *"Unless the key policy explicitly allows it, you cannot use IAM policies to **allow** access
> to a KMS key. Without permission from the key policy, IAM policies that allow permissions have
> **no effect**."*

Three consequences, and the exam tests the first two:

- **Allow is two-sided.** A principal needs `kms:Decrypt` in its IAM policy **and** the key
  policy must permit it. Granting `kms:Decrypt` in IAM alone does nothing.
- **Deny is one-sided**, and AWS says so in as many words — it is not an inference. Immediately after the allow rule (*"Without permission from the key policy, IAM policies that allow permissions have no effect"*) the same page adds, parenthetically: *"(You can use an IAM policy to **deny** a permission to a KMS key **without permission from a key policy**.)"* The governing sentence puts both directions together: *"No AWS principal, including the account root user or key creator, has any permissions to a KMS key unless they are explicitly allowed, and **never denied**, in a key policy, IAM policy, or grant."* So a deny needs no cooperation from the key policy; an allow needs it absolutely.
- **The default key policy already enables IAM policies**, via a statement granting the account
  root access. So a key created with defaults behaves "normally" and the exception only bites on
  a key whose policy was hand-written and omitted that statement. This is why the rule surprises
  people: it is invisible until someone tightens a key policy.

One more difference: **IAM policies are global, key policies are Regional.** A key policy governs
only the key in its own Region.

When the principal is a **Lambda function**, the name that goes in the key policy is the
function's **execution role ARN** — a function is not an IAM principal, so its own ARN is never
the answer, and a Lambda *resource* policy only controls who may **invoke** it inbound.
*(Verified 2026-09-30.)*

> [!warning] Trap — "grant kms:Decrypt in the IAM policy" offered as the whole fix
> A stem where a Lambda (or EC2 role, or another account) cannot decrypt an SSE-KMS object, and
> the options include adding `kms:Decrypt` to the IAM policy. On its own that **does nothing** if
> the key policy doesn't permit the principal. The complete answer names **both sides**, and the
> key-policy principal is the **execution role**, not the function ARN. The mirror-image trap is
> "modify the key policy of an AWS managed key" — you **cannot**; that is the reason to use a
> **customer managed key** when a stem says "control exactly who may decrypt".

### KMS key types
| | Customer managed | AWS managed (`aws/service`) | AWS owned |
|---|---|---|---|
| Who creates it | **you** | AWS, on first use of a service | AWS, internally |
| Key policy you control | **yes** | **no** | no — invisible to you |
| Rotation | optional; default **365 days**, configurable, plus on-demand | **every year**, not controllable | the service decides |
| Cost | ~$1/month + requests | **free** | free |
| Visible in your account | yes | yes | **no** |
| **Usage auditable in CloudTrail** | **yes** | **yes** | **no** — *"not viewable by the customer"* |
| Counts against your KMS key quota | **yes** | no | no |
| Cross-account sharing of encrypted data | **yes** | **no** | yes (service handles it) |
| Choose this when | cross-account, custom policy, compliance, BYOK | you just want encryption on | never — you don't choose it |

### KMS key policy vs grant (and `kms:ViaService`)
A **grant** is the third authorisation mechanism for a KMS key. AWS: *"A grant is a policy instrument that allows AWS principals or AWS service principals to use KMS keys in cryptographic operations"*, and *"When authorizing access to a KMS key, grants are considered along with key policies and IAM policies."*

| | Key policy (with conditions) | Grant |
|---|---|---|
| Lifetime | durable; changing access means editing the policy | *"often used for temporary permissions because you can create one, use its permissions, and delete it without changing your key policies or IAM policies"*; **retire** or **revoke** removes everything it allowed |
| Scope | the whole key, any principal it names | exactly **one KMS key**, exactly **one grantee** (a principal *or* a service principal, not both), only the documented **grant operations** |
| Allow / deny | can allow or deny | **allow only** |
| Narrowing | condition keys — **`kms:ViaService`** *"limits use of an KMS key to requests from specified AWS services"* (requests a service makes **on your behalf**) | **grant constraints**, e.g. tied to one encryption context |
| Exam trigger | "this key may only be used **via S3**" → `kms:ViaService` | "give one service **short-lived, narrowly scoped** use of a key **without rewriting the key policy**" → grant |

*(Verified 2026-10-14.)*

### Secrets Manager vs SSM Parameter Store
| | Secrets Manager | Parameter Store |
|---|---|---|
| Automatic rotation | **yes** (Lambda, or **managed** rotation for RDS/Aurora master users) | **no** |
| Cost | **per secret per month** + API calls | Standard **free**; Advanced paid |
| Max value size | 64 KB | **4 KB** standard / **8 KB** advanced |
| Cross-account access | via resource policy | Advanced tier only |
| KMS encryption | always | only for `SecureString` |
| Exam trigger | "**rotate** the database password automatically" | "store configuration/licence keys cheaply", "hierarchy of parameters" |

### Which detection service
| The stem says | Service | Because its input is |
|---|---|---|
| "unusual API calls", "crypto-mining", "compromised instance calling a known bad IP" | **GuardDuty** | CloudTrail + VPC Flow Logs + DNS logs |
| "suspicious access patterns on an S3 bucket", "data exfiltration from S3" | **GuardDuty with S3 Protection** — still GuardDuty, even though CloudTrail is the log underneath | CloudTrail **S3 data events** (object-level API calls) *(Verified 2026-10-14.)* |
| "unpatched software", "CVE", "vulnerability scan of our EC2/containers" | **Inspector** | the software on EC2, ECR images, Lambda |
| "PII", "credit card numbers", "is there sensitive data in our buckets" | **Macie** | **S3 objects only** |
| "single pane of glass", "aggregate findings", "CIS benchmark compliance" | **Security Hub** — AWS now names the aggregator **Security Hub CSPM** in current service docs, so either wording may appear | other services' findings |
| "centralise security **logs** from all accounts and Regions into S3", "normalise to a standard schema (OCSF)", "security data lake" | **Security Lake** — not Security Hub, which aggregates *findings* | raw log and event data, normalised to OCSF in **your** S3 *(Verified 2026-10-14.)* |
| "investigate the root cause of this finding", "visualise the relationships" | **Detective** | the same logs, as a behaviour graph |
| "central firewall rules across all accounts in the org" | **Firewall Manager** | WAF/Shield/SG policies, org-wide |

### Shield Standard vs Advanced vs WAF
| | Shield Standard | Shield Advanced | WAF |
|---|---|---|---|
| Protects against | L3/L4 DDoS | L3/L4/L7 DDoS | **L7 application** attacks (SQLi, XSS, bots) |
| Cost | **free, automatic** | **$3,000/mo, 1-year commitment** | per web ACL + per rule + per request |
| Extras | — | 24×7 SRT access, **DDoS cost protection**, WAF included on protected resources **up to 50 bn requests/month** | rate-based rules, managed rule groups, CAPTCHA |
| You configure rules | no | no | **yes** |

### CloudHSM vs KMS
| | KMS | CloudHSM |
|---|---|---|
| Tenancy | multi-tenant, AWS-managed | **dedicated single-tenant HSM** |
| Who holds the keys | AWS, in **FIPS 140-3 Security Level 3** validated HSMs (AWS: *"deployed in all AWS Regions where AWS KMS is offered"*; China Regions use OSCCA-certified HSMs instead) | **you** — AWS cannot access them |
| Key control | key policies, IAM | you manage users and keys in the HSM |
| Supports | symmetric, asymmetric, HMAC | full suite incl. **SSL offload, custom crypto** |
| Exam trigger | almost everything — **including "FIPS 140-3 Level 3"**, since KMS's own HSMs are Level 3 validated in every KMS Region | "**we must control the keys**", **single-tenant / dedicated** hardware, "AWS must have no access to the key material", a regulator naming the HSM itself |

### ACM — where the certificate has to live

AWS Certificate Manager issues and **auto-renews** free public TLS certificates. Two facts
carry almost every ACM question:

**Region.** A certificate is **regional**, and it can only be attached to something in its own
Region — except for **CloudFront**, which is global and requires its certificate in
**us-east-1 (N. Virginia)** — and so does anything fronted by CloudFront, notably an
**edge-optimized API Gateway** custom domain (a Regional API uses its own Region; [[19-serverless]]). An ALB in `eu-west-1` needs its certificate in `eu-west-1`; a
CloudFront distribution serving the same site needs one in `us-east-1`. The same site can
therefore need two.

**Validation.** You prove you own the domain by **DNS validation** (add a CNAME — and if the
zone is in Route 53, ACM can write it for you) or **email validation**. DNS validation is the
one to pick, because it is what lets ACM **renew automatically** for as long as the certificate is in use; email validation
needs a human every time.

**Non-exportable** public certificates from ACM — the kind you attach to an ALB, CloudFront or
API Gateway — are **free** ("Public certificate (non-exportable): No cost"). Since June 2025 ACM
also issues **exportable** public certificates, and those are **paid**: **$7.00 per standard
FQDN** and **$79.00 per wildcard**, charged at issuance and again at each renewal. **ACM Private
CA** remains a separate, paid service for issuing internal certificates, and it is the answer
only when the scenario says *internal* or *private PKI*. *(Verified 2026-10-07.)*

> [!warning] Trap — a regional certificate offered for CloudFront
> CloudFront is global and takes its certificate **only from us-east-1**, no matter where the
> origin or the bucket sits. An option that requests the certificate "in the same Region as
> the ALB" and attaches it to a distribution is wrong by construction. The inverse is also
> offered: a certificate in us-east-1 attached to a regional ALB somewhere else — equally
> wrong. And if a question mentions certificates **expiring**, the answer is usually to move
> from **email to DNS validation** so renewal stops needing a human.

> In one line: certificates are regional and auto-renew with DNS validation, but CloudFront
> (and an edge-optimized API Gateway domain) takes its certificate from us-east-1 only.

> [!warning] Trap — "AWS managed" chosen as a service's default encryption key
> The three key types are near-identical strings and the question is usually *"why is there
> no encryption detail in CloudTrail?"*. The answer is that the default is an **AWS owned**
> key, and AWS owned key usage is **not visible to you at all** — not in the console, not in
> CloudTrail. **AWS managed** keys *are* auditable in CloudTrail, so picking them makes the
> scenario's symptom impossible. The rule behind it: **AWS managed is a legacy type, not
> created for new services since 2021**, so "the default" for anything modern is AWS owned.
> **DynamoDB is the canonical example** — always encrypted, no off switch, AWS owned by
> default. And "Customer managed" is never a default anywhere, because you have to create it.

### Rate limiting is a WAF feature, and disabling GuardDuty destroys findings

Two edge/detection details that were each missed on confidence.

**Rate-based rules belong to WAF, not Shield.** AWS: *"A rate-based rule counts incoming
requests and rate limits requests when they are coming at too fast a rate."* So a stem
describing *"attackers make 100 requests per second while normal users make about 10"* is a
**WAF rate-based rule** — a threshold you set on request rate from a source. **Shield
Advanced** adds DDoS cost protection, richer L3/L4 detection and the **Shield Response Team**;
it does not give you a request-rate threshold to configure. Shield Advanced *includes* WAF at
no extra cost, which is why both appear as options — but the thing doing the rate limiting is
still WAF.

**AWS Firewall Manager is the multi-account layer above WAF.** It centrally configures and
enforces WAF rules (and Shield Advanced, security groups) across accounts in an Organization.
One account, one Region → **WAF directly**. Many accounts, or "centrally configure and keep
them consistent" → **Firewall Manager**.

**GuardDuty: suspend keeps findings, disable destroys them.** Verbatim: suspending means
*"it no longer monitors… Your existing findings remain intact"*, and you can re-enable.
Disabling means *"your existing findings and the GuardDuty configuration are lost and can't be
recovered"* — export them first if you want them. Disabling is also **per Region**: to turn
GuardDuty off everywhere you must disable it in **each Region** where it is on.

> [!warning] Trap — Shield Advanced offered for a request-rate threshold
> "Block a source making N requests per second" is a **WAF rate-based rule**, every time.
> Shield Advanced is the answer to *"we want DDoS cost protection and 24/7 response support"*,
> not to a configurable rate threshold. Note also that GuardDuty notifications come from an
> **EventBridge rule → SNS** — GuardDuty emits **findings as events**, so the notification path for a finding is an EventBridge rule, not a metric alarm. Do **not** stretch that into "GuardDuty publishes no CloudWatch metrics": it does. See the trap below.

> [!warning] Trap — "GuardDuty publishes no CloudWatch metrics, so eliminate the alarm option"
> The elimination is **too strong and the premise is false** — GuardDuty does publish metrics, in two namespaces. `AWS/GuardDuty` carries **hourly usage** metrics (`AnalyzedCount`, `AnalyzedBytes`, `MonitoredVcpuHours`, `MonitoredAcuHours`, `ScannedBytes`), dimensioned by `AccountId` and `DataSource`, and AWS offers them explicitly *"to create custom dashboards and alarms"*. `AWS/GuardDuty/MalwareProtection` carries S3 scan metrics (`CompletedScanCount`, `FailedScanCount`, `SkippedScanCount`, `InfectedScanCount`, `CompletedScanBytes`).
> What survives is the narrower, true claim: **those are usage, cost and scan metrics — none of them counts findings or their severity.** So "alarm when a high-severity finding appears" still has to go **finding → EventBridge → SNS/Lambda**, while "alarm when GuardDuty's analysed volume spikes" genuinely is a CloudWatch alarm. Reason from *which* metric the stem needs, not from "GuardDuty has no metrics".

> [!warning] Trap — "disable GuardDuty" chosen when the findings must survive
> They are opposites. **Suspend** stops monitoring and billing but **keeps** existing findings
> and lets you re-enable. **Disable** loses the findings and the configuration permanently.
> If the stem says the company wants to stop using GuardDuty but keep the findings, the answer
> is **suspend** — or **export to S3 first, then disable**.

## Worked examples

> [!example] Worked example — encrypting a 500 MB object with a 4 KB limit
> You cannot call `Encrypt` on a 500 MB file; the limit is 4,096 bytes. What actually happens — and what S3 SSE-KMS does on your behalf — is **envelope encryption**:
>
> 1. Call **`GenerateDataKey`** against your KMS key. It returns a **plaintext data key** and an **encrypted copy** of that same key.
> 2. Encrypt the 500 MB locally with the plaintext key (fast, local, no network).
> 3. **Discard the plaintext key** from memory. Store the **encrypted** data key next to the ciphertext.
> 4. To read: send the encrypted data key to **`Decrypt`**, get the plaintext key back, decrypt locally.
>
> KMS never sees the 500 MB, only the 32-byte key. This is also why key rotation doesn't re-encrypt anything — your objects are encrypted with *data keys*, and rotation changes the key material that wraps them, not the data keys themselves.

> [!failure] Failure mode — the cross-account restore that cannot decrypt
> A team encrypts RDS snapshots with the default `aws/rds` **AWS managed key**, then tries to share a snapshot with another account. It fails, and no amount of IAM policy fixes it: you cannot modify the key policy of an AWS managed key, and a snapshot encrypted under one cannot be shared cross-account at all.
>
> The fix is structural, not permissions: use a **customer managed key**, add the other account as a principal in the **key policy**, re-encrypt the snapshot by copying it with the CMK, then share. The same shape appears with encrypted AMIs and EBS snapshots. Any stem combining "encrypted" with "another account" is pointing at a customer managed key.

## ⚠️ Traps — why the wrong answer looks right

> [!warning] Trap — "delete the KMS key" offered as the way to revoke access now
> Key deletion is **not** an immediate control: the shortest waiting period is **7 days** and
> the default is **30**, so nothing about it is fast. It is also the most destructive option on
> the page — when the period expires, every object encrypted under that key is unrecoverable
> forever. To cut access *now*, change the **key policy** or the IAM policy, or **disable** the
> key — all immediate and all reversible. Deletion is for a key you are certain nothing will
> ever need again, and until the period ends the key sits in **`Pending deletion`**, unusable
> but still cancellable.

> [!warning] Trap — CloudFront Geo Restriction offered for an ALB
> "Block traffic from these countries" has **two** answers and the architecture picks one.
> **CloudFront Geo Restriction** is a property of a **CloudFront distribution** — it does not
> exist if there is no distribution. **WAF's geo match rule statement** blocks by country and a
> **web ACL attaches directly to an ALB** (also API Gateway REST APIs and AppSync). So an
> **ALB-only** architecture with no CloudFront in front of it is a **WAF** answer, every time.
> If CloudFront *is* in the path, either works and Geo Restriction is the cheaper one — but read
> what the stem actually has deployed before choosing.

> [!warning] Trap — rotation re-encrypts your data
> It does not. *"Key rotation has no effect on the data that the KMS key protects. It does not rotate the data keys that the KMS key generated or re-encrypt any data protected by the KMS key."* Old key material is retained so old ciphertext still decrypts, and the **key ID is unchanged** — which is why rotation is transparent to applications and requires no code change.

> [!warning] Trap — "rotate this asymmetric key automatically"
> Automatic rotation is *"supported only on symmetric encryption KMS keys with key material that AWS KMS generates."* **Asymmetric keys, HMAC keys and custom-key-store keys cannot auto-rotate** — the answer is manual rotation (create a new key, repoint the alias).

> [!warning] Trap — Parameter Store for a rotating password
> Parameter Store has **no rotation**. `SecureString` encrypts a value with KMS; it does not change it on a schedule. "Automatically rotate the credential every 30 days" is **Secrets Manager**, every time. The reverse trap also appears: if the stem stresses *cost* for thousands of plain config values, Secrets Manager's per-secret fee makes Parameter Store the answer.

> [!warning] Trap — Macie on anything other than S3
> Macie is *"a data security service that discovers sensitive data"* in **Amazon S3**. It does not scan RDS, EBS, DynamoDB or EFS. If the data in the stem isn't in S3, Macie is the distractor.

> [!warning] Trap — WAF on a Network Load Balancer
> A web ACL attaches to an **ALB**, API Gateway REST API, AppSync, Cognito user pool, App Runner, Amplify, Verified Access — or **CloudFront**. **Not an NLB, not an EC2 instance directly.** WAF inspects HTTP(S), and an NLB operates at layer 4 where there is no HTTP to inspect. If the architecture in the stem has an NLB and the requirement is L7 filtering, something else in the answer must change.

> [!warning] Trap — Shield Advanced to block SQL injection
> Shield is **DDoS**. SQL injection, XSS and bad bots are **WAF**. Shield Advanced adds layer-7 DDoS mitigation and *covers* your standard WAF costs on protected resources, but it is not where you write "block requests containing `' OR 1=1`". Rules are a WAF concept.

> [!warning] Trap — GuardDuty needs you to turn on flow logs
> It does not — for CloudTrail and flow logs. GuardDuty consumes *"an independent and duplicated stream"* of CloudTrail management events and VPC Flow Logs, with nothing to enable. The **DNS** source carries a condition worth knowing: GuardDuty reads Route 53 Resolver query logs only if your instances use the **AWS DNS resolvers** (the default); point them at a third-party resolver and GuardDuty loses that signal. So the **foundational** sources are CloudTrail management events, VPC Flow Logs and Route 53 DNS query logs — *"You don't need to enable anything else"* for those, and enabling or disabling your own flow logs changes nothing about GuardDuty. Options telling you to configure the data sources first are the distractor.

> [!warning] Trap — GuardDuty eliminated for "suspicious access to an S3 bucket" because it only reads three sources
> The three foundational sources are not the whole of GuardDuty. **S3 Protection** is a separate plan: *"GuardDuty monitors AWS CloudTrail data events for Amazon S3, that includes object-level API operations"* — and *"you don't need to explicitly enable or configure S3 data event logging in AWS CloudTrail"*. It is switched on automatically the first time you enable GuardDuty in a Region. So "detect suspicious access to S3 / data exfiltration" is **GuardDuty**: CloudTrail records the calls, GuardDuty analyses them for threats. Inspector scans software and Macie finds sensitive data — neither is threat detection on S3 access. *(Verified 2026-10-14.)*

> [!warning] Trap — Security Hub, Inspector or Macie offered for AWS's own SOC / PCI / ISO reports
> **AWS Artifact** is the portal for **AWS's own** compliance paperwork: *"on-demand downloads of AWS security and compliance documents"* — SOC, PCI and ISO reports — and the place to accept agreements such as the **HIPAA BAA**. It is free. **Security Hub** is tempting because it also does compliance, but the other way round: it checks **your** resources against CIS or PCI rules. Axis: **AWS's audit reports and agreements → Artifact**; **checking your environment → Security Hub**. *(Verified 2026-10-14.)*

> [!warning] Trap — KMS multi-Region keys offered for cross-Region snapshot or object replication
> A **multi-Region key** has replicas in other Regions that *"have the same key material and key ID, so you can encrypt data in one AWS Region and decrypt it in a different AWS Region"*. Sounds perfect for DR — but AWS services mostly ignore that: *"Most AWS services that integrate with AWS KMS for encryption at rest or digital signatures currently treat multi-Region keys as though they were single-Region keys."* A cross-Region snapshot copy or S3 replication **re-encrypts with a key in the destination Region** anyway. So "copy encrypted snapshots to another Region" = **name a destination-Region key on the copy** ([[07-rds-aurora]]). Multi-Region keys are for **your own app** encrypting in one Region and decrypting in another. An existing key can't be converted to one. *(Verified 2026-10-14.)*

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **WAF IP set for an edge allow-list** — open miss, gap closed 2026-10-15. *(Trainer-sourced.)*
- [ ] **DDoS best practices** — open miss, gap closed 2026-10-15. *(Trainer-sourced.)*
*Not yet measured — written from the video section rather than a drill. These are where courses commonly teach a stale or half-fact, so check yourself against them first; real misses get added after the next mock.*

- [ ] **AWS managed key rotation is yearly, not three-yearly** — AWS changed it in May 2022 and a lot of material still says 1,095 days.
- [ ] **KMS rotation period is configurable now**, and **on-demand rotation exists** (max 25 per key). "Exactly once a year, fixed" is the old answer.
- [ ] **The 4 KB limit is the reason for envelope encryption**, not a quota to recite. Be able to say what `GenerateDataKey` returns and why there are two versions of the key.
- [ ] **Which detection service by INPUT** — GuardDuty reads logs, Inspector reads software, Macie reads S3 objects. Naming the input picks the service faster than recalling a description.
- [ ] **Secrets Manager rotates, Parameter Store does not.** SecureString is encryption, not rotation.
- [ ] **WAF cannot attach to an NLB** — no HTTP at layer 4 to inspect.

> [!tip] Production gap
> This note is exam-shaped. Production adds **Firewall Manager** to push WAF and security-group policies across an Organization, **Security Hub** standards (CIS, AWS Foundational) with automated remediation, KMS **multi-Region keys** for client-side encryption across Regions (see the trap above for where they do *not* help), **grants** and `kms:ViaService` (compared above), ACM **Private CA** for internal TLS, and CloudHSM where a regulator requires single-tenant hardware.

## 🔗 Docs
- [WAF IP set match](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-ipset-match.html) · [DDoS mitigation techniques](https://docs.aws.amazon.com/whitepapers/latest/aws-best-practices-ddos-resiliency/mitigation-techniques.html) · [Attack surface reduction](https://docs.aws.amazon.com/whitepapers/latest/aws-best-practices-ddos-resiliency/attack-surface-reduction.html); verified 2026-10-15
- [Key policies in AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html) — *"(You can use an IAM policy to deny a permission to a KMS key without permission from a key policy.)"*, and the "explicitly allowed, and never denied" rule; **verified 2026-10-10**
- [`access-keys-rotated`](https://docs.aws.amazon.com/config/latest/developerguide/access-keys-rotated.html) — `maxAccessKeyAge` default **90**, Periodic trigger, `AWS::IAM::User`, root keys excluded; **verified 2026-10-10**
- [Importing certificates into ACM](https://docs.aws.amazon.com/acm/latest/userguide/import-certificate.html) — no managed renewal for imported certs, the IAM store fallback, "you cannot manage your certificates from the IAM Console"; **verified 2026-10-10**
- [Monitoring GuardDuty usage and estimating costs](https://docs.aws.amazon.com/guardduty/latest/ug/monitoring_costs.html) — the `AWS/GuardDuty` hourly usage metrics and `AWS/GuardDuty/MalwareProtection` scan metrics, and that none of them counts findings; **verified 2026-10-10**
- [AWS CloudHSM key stores](https://docs.aws.amazon.com/kms/latest/developerguide/keystore-cloudhsm.html) · [Shield Advanced subscription and consolidated billing](https://docs.aws.amazon.com/waf/latest/developerguide/ddos-advanced-summary.html)
- [WAF geographic match rule statement](https://docs.aws.amazon.com/waf/latest/developerguide/waf-rule-statement-type-geo-match.html)
- [KMS key policies — IAM policies have no effect without key-policy permission](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)
- [Deleting AWS KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html)

- [AWS KMS keys — concepts](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html) — the three key types side by side; "AWS managed keys are a legacy key type that is no longer being created for new AWS services as of 2021"; AWS owned logging "Not viewable by the customer"; verified 2026-09-27
- [DynamoDB encryption at rest](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/EncryptionAtRest.html) — "AWS owned key – Default encryption type"; all data always encrypted; DAX uses an AWS managed key; verified 2026-09-27
- [KMS key rotation](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html) — 365-day default, configurable, on-demand, what cannot rotate; verified 2026-09-25
- [KMS `Encrypt` API](https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) — the 4,096-byte limit; verified 2026-09-25
- [KMS resource quotas](https://docs.aws.amazon.com/kms/latest/developerguide/resource-limits.html) — keys, aliases, grants; verified 2026-09-25
- [Parameter Store tiers](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-advanced-parameters.html) — standard vs advanced; verified 2026-09-25
- [GuardDuty data sources](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_data-sources.html) — headed "GuardDuty foundational data sources"; verified 2026-09-25, scope re-checked 2026-10-14
- [GuardDuty S3 Protection](https://docs.aws.amazon.com/guardduty/latest/ug/s3-protection.html) — CloudTrail S3 data events, no CloudTrail data-event logging needed, unauthenticated access not processed, auto-enabled with the free trial; **verified 2026-10-14**
- [What is Amazon Security Lake](https://docs.aws.amazon.com/security-lake/latest/userguide/what-is-security-lake.html) — OCSF + Parquet, accounts and Regions, rollup Regions, subscribers; **verified 2026-10-14**
- [What is AWS Artifact](https://docs.aws.amazon.com/artifact/latest/ug/what-is-aws-artifact.html) · [Managing agreements](https://docs.aws.amazon.com/artifact/latest/ug/managing-agreements.html) · [Downloading documents](https://docs.aws.amazon.com/artifact/latest/ug/downloading-documents.html) — ISO/PCI/SOC reports, BAA for HIPAA; **verified 2026-10-14**
- [What is Security Hub CSPM](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html) — control checks against CIS and PCI DSS on your resources; **verified 2026-10-14**
- [Multi-Region keys](https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html) — same key material and key ID; services treat MRKs as single-Region; single-Region keys the default best fit; **verified 2026-10-14**
- [Copying an EBS snapshot](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-copy-snapshot.html) — a copy can use a different KMS key from the source; **verified 2026-10-14**
- [KMS grants](https://docs.aws.amazon.com/kms/latest/developerguide/grants.html) · [KMS condition keys (`kms:ViaService`)](https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html) — grant scope, retire/revoke, grant tokens, constraints; ViaService "only applies for Forward access sessions"; **verified 2026-10-14**
- [What is Amazon Inspector](https://docs.aws.amazon.com/inspector/latest/user/what-is-inspector.html) — EC2/ECR/Lambda, continuous; verified 2026-09-25
- [What is Amazon Macie](https://docs.aws.amazon.com/macie/latest/user/what-is-macie.html) — S3 only; verified 2026-09-25
- [Associating a web ACL with a resource](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-associating-aws-resource.html) — supported targets; verified 2026-09-25
- [AWS Shield pricing](https://aws.amazon.com/shield/pricing/) — Standard free, Advanced $3,000/mo + 1-year commitment; verified 2026-09-25
