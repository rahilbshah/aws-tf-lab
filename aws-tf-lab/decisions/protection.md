---
decision: protection
question: How should this be encrypted, shielded and watched?
spans: [21-security, 09-s3-security, 11-cloudfront]
tags: [decision, domain/secure]
---

# How should this be encrypted, shielded and watched?

Three jobs hide inside the word "security" and they fail independently: **custody** of
keys and data, **shielding** against traffic you did not invite, and **watching** for what
already went wrong. Find the job, then work top-down — the first question that applies
settles it.

## 1. Encryption — the axis is custody, not strength

Everything is encrypted at rest by default, so "should this be encrypted" never decides
anything. Ask **who must hold the key, and must its use be logged?**

- **Nobody needs to hold it** → SSE-S3, or the AWS managed key (`aws/s3`, `aws/rds`). Free,
  zero admin, and **no key policy you can edit**.
- **You must control who may decrypt, or you need CloudTrail on every use** → a **customer
  managed KMS key**. Also the only answer that survives cross-account.
- **A regulator wants single-tenant hardware, or AWS must be unable to touch the key** →
  **CloudHSM**.
- **AWS must never see plaintext** → **client-side**, or SSE-C to keep S3 doing the work
  while you carry the key on every request.

Decided **when the data is written**, not when someone later asks to share it.

↳ [[21-security#KMS key types]] · [[21-security#CloudHSM vs KMS]] · [[09-s3-security#Encryption is a question about custody, not about whether]]

## 2. Secrets — the axis is "does the value change on a schedule?"

- **It must rotate** → **Secrets Manager**. An RDS or Aurora master user rotates itself,
  with no Lambda to write.
- **It is a config value** → **Parameter Store**, free at Standard. `SecureString` is
  encryption, not rotation — it does not move the answer.
- **Thousands of plain values and cost is stated** → Parameter Store even where a secret
  would feel tidier; Secrets Manager bills per secret per month.

↳ [[21-security#Secrets Manager vs SSM Parameter Store]]

## 3. Reaching the object — the axis is "does the reader have an AWS identity?"

- **An identity in your account** → an **IAM policy**, nothing else.
- **An identity in another account** → **bucket policy *and* their IAM policy**; you can
  only ever write half of it.
- **No AWS identity, one object, short window** → an **S3 presigned URL**: the generator's
  permissions, and a bearer token.
- **No AWS identity, content already behind CloudFront** → a **CloudFront signed URL** for
  one file, **signed cookies** for many.
- **Only the CDN may reach the origin** → **OAC** with the `AWS:SourceArn` condition naming
  your distribution, Block Public Access left fully on.

Over all of it: **Block Public Access overrides a policy**, it is not outvoted by one.

↳ [[09-s3-security#Two policies pointing at each other]] · [[09-s3-security#A presigned URL is a bearer token wearing your permissions]] · [[11-cloudfront#Signed URLs vs signed cookies (private content)]]

## 4. Immutability — the axis is "who must be unable to delete it?"

- **An ordinary mistake** → **versioning**. Recoverable, but anyone holding delete
  permission still wins.
- **Internal policy, senior override allowed** → Object Lock, **GOVERNANCE**.
- **A regulator, and nobody — including root** → **COMPLIANCE**. A one-way door whose
  documented escape is closing the account; never on an account you keep.
- **Permanent deletes and disabling versioning specifically** → **MFA Delete**: root plus
  an MFA device, CLI only, no Terraform surface.

↳ [[09-s3-security#Object Lock, and the delete that succeeds anyway]] · [[09-s3-security#GOVERNANCE vs COMPLIANCE]]

## 5. Shielding — the axis is which layer the attack is at

- **L3/L4 volumetric** → **Shield Standard**. Already on, free, nothing to decide.
- **L7 request content** — SQLi, XSS, bots, rate limiting → **WAF**, attached to something
  that speaks HTTP. Never an NLB, never an EC2 instance.
- **The bill from an attack, or a human to call during one** → **Shield Advanced**:
  $3,000/month on a year's commitment, so it needs a stated reason.
- **Whole countries** → CloudFront **geo restriction** (may they in at all), not Route 53
  geolocation (where they are sent).
- **The same rules across every account in the org** → **Firewall Manager**.

↳ [[21-security#Shield Standard vs Advanced vs WAF]]

## 6. Watching — the axis is the input, not the finding

Name what the service *reads* and it picks itself: logs → **GuardDuty**; installed software → **Inspector**;
S3 objects → **Macie**; other services' findings → **Security Hub**; one finding's root cause → **Detective**.

↳ [[21-security#Which detection service]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **A presigned URL for content served through CloudFront.** It works — and sends the viewer
  straight to S3, past WAF, geo restriction and the OAC lock. Sign at the front door.
- **SSE-KMS chosen for the audit trail, then CloudFront 403s.** A customer managed key on the origin means
  **CloudFront must be in the KMS key policy** too, and legacy OAI cannot read SSE-KMS at all.
- **An S3 website endpoint when the requirement was "private".** Website endpoints are *custom* origins — no
  OAC, no OAI — so one forces the bucket public. Private means the REST endpoint, losing S3's site features.
- **WAF on CloudFront while the origin stays publicly reachable.** Edge filtering only sees
  traffic that came through the edge; an internet-facing ALB still answers direct requests.
- **Security Hub enabled with nothing underneath it.** It has no detectors of its own — the
  detection decision comes first, aggregation second.
- **An AWS managed key blocking a share nobody has asked for yet.** A snapshot encrypted
  under `aws/rds` cannot go cross-account, and that key policy cannot be edited to fix it.
- **The certificate requested where the application lives.** Anything viewers reach through
  CloudFront needs its ACM certificate in **us-east-1** whatever Region the ALB or bucket is
  in — and one elsewhere does not error, it simply never appears in the list.
