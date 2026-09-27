---
decision: identity
question: Who is this, and what may they do?
spans: [01-iam, 01-iam-advanced, 19-serverless, 24-other-services]
tags: [decision, domain/secure]
---

# Who is this, and what may they do?

Two decisions live here — *who the caller is*, and *where the rule about them is written*.
Settle the first, then the second. Top-down; the first question that applies settles it.

## 1. Who owns the identity?

The axis is who the caller belongs to, not what they will do.

| The caller | Go to |
|---|---|
| an employee of the company | §2 |
| an end user of the company's own product | §3 |
| code running inside AWS | §4 |
| a caller from outside AWS | §5 |

## 2. Employees — do the identities already exist?

**Yes, in Active Directory or any corporate IdP** → **IAM Identity Center**. Do not create
IAM users: copy the identity and someone now has to be deprovisioned twice. AD group →
permission set → **IAM role**.

Which directory sits behind it turns on **may directory data live in AWS?**

- **No — the only copy stays on-premises** → **AD Connector**, a proxy that stores nothing.
- **Yes, and AD-aware workloads need real AD in the cloud** → **AWS Managed Microsoft AD**.
- **Simple AD** is eliminated the moment trusts, MFA, LDAPS, schema extensions or RDS for
  SQL Server appear. It supports none of them.
- **Nothing exists yet** → an **IAM user**, for break-glass or a legacy service account only.

↳ [[01-iam#Bringing existing corporate identities into AWS (Directory Service + federation)]] · [[24-other-services#Directory Service options]]

## 3. The product's own end users → Cognito

No fork. People who sign up for your product are not workforce identity and a directory is the wrong shape for them — **Cognito**, social sign-in included, at any scale.

↳ [[24-other-services#AWS Directory Service — three options, one real discriminator]]

## 4. Code inside AWS → a role, always

No fork about *whether*: compute gets a **role**, never an access key. Only **how it
reaches it**.

- **EC2** → through an **instance profile**. A role cannot be attached to an instance.
- **Lambda, ECS, everything else** → the role directly.
- Both policies are required and fail differently: no **trust policy** and the door never
  opens; no **permissions policy** and it opens onto an empty room.

↳ [[01-iam#Trust policy vs Permissions policy (on a Role)]] · [[01-iam#The instance profile — the wrapper the console hides]]

## 5. Callers from outside AWS

Ask **what issues the identity**. The trust policy does the work in every row; only the principal it names changes.

| The caller | Answer |
|---|---|
| another AWS account — a vendor, an auditor | cross-account **role** + an `sts:ExternalId` condition |
| a CI job or workload with an OIDC / SAML issuer | **federation** → role, via `AssumeRoleWith*` |
| a human arriving through the corporate IdP | §2 — same route, nothing new |

↳ [[01-iam#User vs Role]]

## 6. Where does the rule get written?

Ask **is this a grant or a ceiling**, and **whose side is it written on**.

| What you need | Write it as |
|---|---|
| let a principal in my account do X | **identity policy** |
| let a principal *outside* my account reach my resource | **resource policy** |
| cap everyone in these accounts | **SCP** — needs Organizations, all features |
| cap this one user or role | **permissions boundary** |
| cap one assumed session | **session policy** |
| permissions that track teams without a policy per team | **ABAC** — tags on caller vs resource |

Only the resource policy adds access; everything else subtracts, and an explicit `Deny` anywhere ends the argument.

↳ [[01-iam-advanced#The four things that can cap a permission]] · [[01-iam-advanced#How policy types combine]] · [[01-iam-advanced#RBAC vs ABAC]]

## 7. When what is being authenticated is not an AWS API

- **A database login** turns on **is a password stored anywhere?** No → **IAM database
  authentication** (`rds-db:connect`, 15-minute token). Yes, but rotate it → **Secrets Manager**.
- **An API front door** turns on **who the caller is**: an AWS principal → **IAM** auth; a
  logged-in end user → **Cognito**; your own scheme → a **Lambda authorizer**.

↳ [[01-iam#How an application authenticates to RDS]] · [[19-serverless#⚠️ Traps — why the wrong answer looks right]]

## The forks people take wrongly

- **Directory Service for a SaaS product's users.** Managed AD is workforce identity;
  customers signing up are Cognito. Backwards, you scale a directory to millions.
- **AD Connector versus Managed Microsoft AD.** "Store nothing in AWS" is AD Connector. A
  buried **RDS for SQL Server** requirement collapses all three options to Managed AD.
- **An IAM group as the landing point for a federated identity.** A group holds only IAM
  users, and a federated identity has none. The AD group maps to a **role**.
- **Reaching for an SCP to give someone access.** An SCP never grants. "Use an SCP to allow
  the developers S3" is the distractor — the identity policy is still missing.
- **SCP where a boundary belongs.** One account delegating admin duties → **boundary**,
  which also works standalone. Enforce across every account → **SCP**, which does not.
- **Answering "no stored password" with TLS.** `--ssl-ca` changes how a connection is
  *encrypted*, never who may log in. And `rds:*` is management — login is `rds-db:connect`.
- **API keys as authentication.** API Gateway keys meter and throttle a caller; they prove nothing about identity. Offered as the security control, they are the distractor.
