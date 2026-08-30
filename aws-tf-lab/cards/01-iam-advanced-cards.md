---
topic: 01-iam-advanced
domain: secure
related_note: 01-iam-advanced
tags: [flashcards/iam]
---

# Cards for [[01-iam-advanced]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

Does a Service Control Policy grant permissions?
?
Never. AWS states it plainly: "No permissions are granted by an SCP." An SCP defines a permissions guardrail — the MAXIMUM available permissions. You still need identity-based or resource-based policies to actually grant anything. A user with no IAM policy has no access no matter how permissive the SCP.

Which accounts do SCPs affect, and is the root user exempt?
?
Member accounts only — the MANAGEMENT account and everything in it is completely exempt (that's why you keep no workloads there). But a MEMBER account's root user IS capped by SCPs like everyone else. That asymmetry is the most-tested SCP fact.

For an action to be allowed by SCPs, what must be true at each level of the OU hierarchy?
?
There must be an explicit Allow covering that action at EVERY level — the root, every OU in the direct path, and the account itself. SCP evaluation is deny-by-default. Conversely a Deny at ANY single level blocks the action for everything beneath it.

What is FullAWSAccess and why does removing it break everything?
?
An AWS managed SCP allowing all services and actions, auto-attached to every root, OU and account. Because SCPs need an explicit Allow at every level, removing FullAWSAccess without attaching a replacement Allow means no Allow exists in the path — so every action in that subtree is denied, not just the ones you meant to block.

What feature set must AWS Organizations have for SCPs to work?
?
All features (the default). SCPs are not available in consolidated-billing-only mode. Upgrading from consolidated billing to all features requires every invited member account to accept the change.

Name things SCPs cannot restrict.
?
Anything done by the management account; anything done through a service-linked role; registering for Enterprise Support as root; CloudFront trusted-signer functionality; configuring reverse DNS for Lightsail/EC2 as root. SCPs also don't reach principals in accounts outside your organization — a bucket policy granting an external account is unaffected.

What is an IAM permissions boundary?
?
A managed policy that sets the MAXIMUM permissions an identity-based policy can grant to one IAM user or role. It grants nothing itself. Effective permissions = the intersection of the identity-based policy and the boundary. Note it applies to users and roles — NOT to groups.

SCP vs permissions boundary — how do you choose?
?
Same idea, different blast radius. SCP caps entire ACCOUNTS and requires AWS Organizations with all features. A permissions boundary caps ONE user or role and works in a standalone account. "Prevent anyone in any account from…" → SCP. "Let this junior admin create users but not admins" → boundary.

How do you let someone create IAM users without letting them create an admin?
?
Give them a permissions policy allowing iam:CreateUser, but put a permissions boundary on THEM that allows those IAM actions only under the condition `StringEquals {"iam:PermissionsBoundary": "<arn of the boundary policy>"}`, plus an explicit Deny on editing or deleting boundary policies. They then physically cannot create a principal without stamping the boundary on it — the call fails with AccessDenied.

Identity-based policy + resource-based policy: union or intersection?
?
UNION. If either one allows the action, it's allowed (explicit Deny in either still wins). This is the odd one out and it's why cross-account S3 access works from the bucket policy alone.

Identity-based policy + permissions boundary: union or intersection? And with an SCP?
?
Both INTERSECTION. Identity + boundary: both must allow. Identity + SCP: both must allow. If an SCP, a boundary and an identity policy all apply, all THREE must allow. An explicit Deny in any of them overrides everything.

Do implicit denies in a permissions boundary limit resource-based policies?
?
No. If a resource-based policy (e.g. on a Secrets Manager secret) grants the user directly and the boundary merely fails to mention that service, the access still works. Only an EXPLICIT Deny in the boundary blocks it. Same nuance applies to session policies.

What is ABAC and which condition keys implement it?
?
Attribute-Based Access Control — access decided by TAGS rather than by which role you hold. `aws:PrincipalTag/<key>` (tags on the caller) compared against `aws:ResourceTag/<key>` (tags on the resource), plus `aws:RequestTag/<key>` for tags being applied. Exam trigger: "scales as teams grow", "avoid writing a new policy per team", "permissions based on project or cost-centre".

Which condition key trusts an entire AWS Organization in one line?
?
`aws:PrincipalOrgID` — matches the organization the calling principal belongs to. It lets a single resource-based policy allow every account in the org without enumerating account IDs, and it stays correct as accounts are added or removed.

Why must MFA conditions use BoolIfExists rather than Bool?
?
Because `aws:MultiFactorAuthPresent` is ABSENT (not false) for requests made with long-term access keys. With a plain Bool test the condition doesn't match at all, so a Deny won't fire and an Allow gated on "true" blocks CLI access-key calls. `BoolIfExists` handles the missing-key case and gives the behaviour you intended.

Why can an IP-allowlist policy fail for traffic inside a VPC?
?
`aws:SourceIp` is not present in the request context when the request goes through a VPC endpoint, so the condition never matches and access is denied. Use `aws:VpcSourceIp`, or scope on `aws:SourceVpce` / `aws:SourceVpc` instead.

What does aws:RequestedRegion do?
?
Matches the Region a request is directed at — the standard way to enforce data residency or cost control ("only eu-west-1"). Typically used as a Deny in an SCP, with a NotAction carve-out for global services (IAM, Route 53, CloudFront, Organizations) that are only reachable via us-east-1.

Organizations: management account vs member account?
?
The management account creates the organization, is the payer, attaches policies, invites/creates accounts, and CANNOT be changed afterwards. Member accounts are everything else; a member account belongs to only one organization at a time and can be designated a delegated administrator. SCPs apply to member accounts only.

What does consolidated billing give you beyond one invoice?
?
Aggregated usage across all accounts, which can earn volume/tiered pricing discounts, plus sharing of Reserved Instances and Savings Plans across the organization. Organizations itself is free — you pay only for what the member accounts consume.

What is AWS Control Tower and how does it relate to Organizations?
?
An orchestration layer ON TOP of Organizations. It builds a landing zone (a best-practice multi-account environment) using Organizations + IAM Identity Center + Service Catalog, provides Account Factory for standardised account vending, applies controls/guardrails, and detects drift. Organizations is the primitive; Control Tower is the prescriptive setup. "Quickly set up a compliant multi-account environment" → Control Tower.

What are Control Tower's three kinds of control, and how is each implemented?
?
Preventive (stops the action — implemented as SCPs), detective (flags non-compliance after the fact — implemented as AWS Config rules), and proactive (blocks non-compliant resources before deployment — CloudFormation hooks). Each control also carries guidance: mandatory, strongly recommended, or elective.

SCP vs RCP?
?
SCPs are principal-centric — they cap what IAM users and roles in member accounts can do. RCPs (resource control policies) are resource-centric — they cap the maximum access permitted TO resources in member accounts, e.g. "only identities from our organization may access our buckets." Both are authorization policies, both require all features, and neither grants anything.

An account admin has AdministratorAccess but still can't launch EC2. Why?
?
An SCP above them denies it — at the root, an OU in their path, or their account. Effective permissions are the intersection of the SCP and their IAM policy, so a Deny (or a missing Allow) at any level in the org path wins regardless of what's attached inside the account. Same symptom is possible from a permissions boundary on that specific principal.

How deep can the OU hierarchy go, and how many roots are there?
?
Exactly one root per organization (created automatically), with OUs nested up to five levels deep beneath it.
