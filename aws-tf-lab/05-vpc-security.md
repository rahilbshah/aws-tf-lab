---
topic: 05-vpc-security
domain: secure
status: reviewed
services: [Security Groups, Network ACLs, VPC Flow Logs, Network Firewall]
related: [05-vpc, 05-vpc-core, 01-iam, 02-ec2]
cards: cards/05-vpc-security-cards
tags: [topic, domain/secure]
---

# 05.2 – VPC Security (SG, NACL, Flow Logs, Network Firewall)

The traffic-control and visibility layers of a VPC: two firewalls (stateful SG, stateless NACL), the log that tells you *why* traffic was allowed or blocked (Flow Logs), and the managed deep-inspection layer (Network Firewall). Part of [[05-vpc]].

## What problem does this solve?

Your instances live in a VPC. Something has to decide which packets are allowed to reach them, and something has to tell you afterwards what that decision was.

AWS gives you two firewalls for the deciding, and they sit in different places.

One wraps each instance's network interface. That's the **security group**. It only knows how to say *yes*: you list what may reach this instance, and anything you didn't list is refused — not by a rule, but by never having been mentioned.

The other wraps the whole subnet. That's the **network ACL**. It can say *no* out loud, and it applies to every instance in that subnet whether or not the person who launched them agreed.

You need both because each can do exactly one thing the other can't. A security group can't block a specific bad IP — it has no deny at all. A network ACL can't follow a conversation — it judges each packet alone, so you have to describe the reply as well as the request. In day-to-day work security groups do about 95% of the job; the NACL is there for those two gaps.

Deciding without seeing is how you lose an afternoon to "the traffic is mysteriously blocked". So **Flow Logs** record every connection — who talked to whom on what port, and whether it was accepted or rejected.

And when address-and-port isn't enough — you need to know what's *inside* the packet, or block by domain name — that's **Network Firewall**.

> In one line: the SG guards the instance and can only allow, the NACL guards the subnet and can deny, and Flow Logs record whether the traffic was allowed or rejected.

## How it actually works

### Stateful versus stateless

Almost everything else in this topic falls out of this one difference.

A security group is **stateful**. When it allows a request in, it remembers that connection. The reply is allowed back out automatically — you never wrote a rule for it, and you don't need one.

A network ACL is **stateless**. It has no memory. Every packet is judged on its own, with no knowledge that it happens to be the answer to something already allowed.

Walk a real one. Someone on the internet loads your web page:

1. Their packet reaches the subnet — **inbound**, destination port 80. The NACL checks its inbound rules, finds your allow for 80, passes it.
2. It reaches the instance's ENI — **inbound** port 80 again. The SG allows 80. Passes.
3. The web server replies. Leaving through the SG — **outbound**. The SG remembers step 2, so no rule is needed.
4. That same reply hits the NACL — **outbound**. The NACL remembers nothing. It looks for an outbound rule matching this packet, and if you never wrote one, the unmatched-traffic deny drops it.

The page hangs. Inbound worked, the reply died, and nothing in the rules you wrote looks wrong — which is why this is the most common NACL mistake there is.

> In one line: the SG remembers the conversation, the NACL sees one packet at a time — so on a NACL you must write both halves.

### Ephemeral ports, and which direction to open them

Step 4 above raises the obvious question: what port is that reply even going to?

Not 80. Port 80 is where the *request* went. The reply goes back to whatever port the client's operating system picked when it opened the connection — a temporary, high-numbered port that's thrown away when the connection closes. That's an **ephemeral port**.

You can't know which one it picked. So you allow the whole range: **1024–65535**.

That range is deliberately a superset. The real range depends on who's at the other end — Linux uses 32768–61000, Windows 2008 and later 49152–65535, and ELB, Lambda and NAT use 1024–65535. Since the other end could be any of them, you open the widest.

Now the part people write backwards. The direction depends on who started the conversation.

| The instance is… | The ephemeral rule goes… | Because |
|---|---|---|
| Receiving requests (a web server) | **outbound** | its reply travels out to the *client's* ephemeral port |
| Initiating requests (calling an API, resolving DNS) | **inbound** | the answer comes back to *its own* ephemeral port |

An instance that does both — most do — needs both.

One more thing hides in here. A NACL rule names a protocol, so a rule set written only for TCP blocks UDP outright — that quietly kills UDP to **external** DNS and NTP servers, and it surfaces as outbound `REJECT` lines in the flow logs rather than as an obvious error. It does not touch the VPC defaults: a NACL **can't filter traffic to the Amazon-provided DNS resolver (VPC+2) or the Amazon Time Sync Service** at all.

> In one line: replies land on 1024–65535 — outbound if you're answering, inbound if you're asking — and a TCP-only rule set silently drops UDP.

### Numbered rules, and first match wins

A security group has no ordering. Every rule is an allow, all of them are evaluated together, and if any one of them permits the traffic it's in. Two rules can never contradict each other.

A NACL *can* contradict itself — it holds allows and denies side by side — so it needs a tiebreaker. The tiebreaker is the rule number.

Custom rules are numbered 1–32766 and read in ascending order. **The first rule that matches decides, and nothing after it is read.** At the end sits a `*` rule you can't remove, denying anything that matched nothing.

So a low number isn't "less important" — it's more. Put `deny 203.0.113.50/32` at #100 and `allow 80/443 from anywhere` at #110, and that IP is blocked: #100 matched first and evaluation stopped there. Write the same deny at #200 and it never runs, because #110 already allowed the packet and the search ended.

Two defaults flip in a way worth pinning down:

|   | The auto-created one | A NEW one you create |
|---|---|---|
| Security group | self-referencing inbound, allow all outbound | denies all inbound, allows all outbound |
| Network ACL | allows everything in and out | **denies everything in and out** |

The default NACL is wide open, which is why a subnet you never configured is effectively filtered by security groups alone. Create a custom NACL and associate it, and you start from deny-all and have to build every flow back up by hand — both directions, ephemeral range included. A subnet has exactly one NACL; leave it unassociated and it uses the default.

> In one line: lowest matching number wins and stops the search — and a custom NACL starts closed while the default one starts open.

### What flow logs can and cannot tell you

A flow log records connection metadata: source and destination address, source and destination port, protocol, packet and byte counts, a start and end time, and `ACCEPT` or `REJECT`. You can attach one at the VPC, subnet or ENI level, and publish to CloudWatch Logs, S3, or Amazon Data Firehose (older material calls it Kinesis Data Firehose).

What a flow log never contains is the payload. No request body, no filename, no URL. If the question is "what data left the network", flow logs cannot answer it — that's Network Firewall's job, or VPC Traffic Mirroring for real packet capture.

Reading them is a small skill worth having. The useful split is:

- `REJECT` + **inbound** + a port you never opened → your firewall working correctly. The internet scans every public IP constantly; this noise is normal.
- `REJECT` + **outbound** + a port your app actually needs → *your own* rule is too strict. That one is the bug.

Two practicalities. The protocol shows up as a number — 6 is TCP, 17 is UDP, 1 is ICMP. And records are batched: the aggregation interval defaults to 600 seconds, and **delivery adds about 5 more minutes to CloudWatch Logs (~10 to S3)** — so while debugging set the interval to 60 and expect logs in roughly six minutes, not fifteen.

Some traffic never appears at all: the Amazon DNS server (a custom DNS resolver *is* logged), DHCP, the instance metadata endpoint `169.254.169.254`, the Amazon Time Sync Service `169.254.169.123`, Windows license activation, and the reserved VPC router address. Silence there is not evidence that something was blocked.

> In one line: flow logs give you who-to-whom-on-what-port plus ACCEPT or REJECT — never the contents.

### Network Firewall, and why it needs a subnet of its own

Security groups and NACLs both stop at IP and port. They can't tell that a packet carries a known exploit, and they can't block `evil.example.com`, because a domain name isn't an address.

Network Firewall is the managed layer for that: a stateful intrusion-prevention system built on Suricata rules, doing deep packet inspection and domain filtering.

The awkward part is where it lives. It isn't a setting you enable on a subnet. It's an endpoint that sits in its **own dedicated firewall subnet**, and traffic only reaches it because you changed route tables to send it there. Skip the routing and the firewall is running, billing, and inspecting nothing.

Which is the other thing to hold on to: security groups and NACLs are free. Network Firewall runs around $0.395/hr per firewall endpoint plus data processing (⚠️ check current). It's not the default answer — it's the answer when the requirement mentions payload, protocol or domain.

> In one line: SG and NACL filter addresses, Network Firewall inspects contents — and it only sees what your route tables send it.

## Exam recap

*Now that the mechanisms are clear, this is the compressed version to revise from.*

> [!info] Exam TL;DR
> - **Security Group** = stateful, instance/ENI-level, **allow-only** (implicit deny for the rest), all rules evaluated together. Return traffic is auto-allowed (stateful).
> - **NACL** = stateless, subnet-level, **allow AND deny**, rules **numbered & evaluated low→high, first match wins**. You must open **both directions** *and* the **ephemeral return ports `1024–65535`** yourself.
> - **Default flip:** default NACL = allow-all; a **new custom NACL = deny-all**. (SGs: new SG denies inbound; default SG self-references.)
> - **Use a NACL when** you need an explicit **DENY** (block an IP/CIDR) or a **subnet-wide guardrail** — the two things an SG fundamentally can't do.
> - **Flow Logs** capture connection **metadata** + **ACCEPT/REJECT** — never payload. Attach at **VPC / subnet / ENI**; publish to **CloudWatch Logs / S3 / Kinesis Firehose**.
> - **Network Firewall** = managed, stateful **IPS (Suricata)** with deep packet inspection + **domain filtering**; lives in a **dedicated firewall subnet** with route tables sending traffic through it. Far beyond SG/NACL (which are just IP/port allow-deny).

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| Security group | `aws_security_group` + `aws_vpc_security_group_ingress_rule`/`egress_rule` | Modern per-rule resources; source can be a CIDR or another SG (`referenced_security_group_id`). |
| Network ACL | `aws_network_acl` (+ inline `ingress`/`egress` or separate `aws_network_acl_rule`) | `rule_no` = precedence (low first), `action = allow/deny` — inline names; the separate resource calls them `rule_number` / `rule_action`. `protocol = -1` for all. |
| Associate NACL ↔ subnets | `subnet_ids` on the NACL, or `aws_network_acl_association` | Each subnet has exactly one NACL (default if unset). |
| Flow log | `aws_flow_log` | `vpc_id`/`subnet_id`/`eni_id` (the level), `traffic_type` (ALL/ACCEPT/REJECT), `log_destination_type`, `max_aggregation_interval` (60 or 600). |
| Log group (CloudWatch dest) | `aws_cloudwatch_log_group` | Needs an IAM **service role** (see below). S3 dest needs a bucket policy instead. |
| Flow-log IAM service role | `aws_iam_role` trusting `vpc-flow-logs.amazonaws.com` + `logs:*` permissions | The trust-vs-permissions split from [[01-iam]], for real. |
| Network Firewall | `aws_networkfirewall_firewall` + `_firewall_policy` + `_rule_group` | *Conceptual-only here* — needs a dedicated firewall subnet + route-table redirection; ~$0.395/hr. |

## Architecture diagram

```mermaid
flowchart TB
    NET([Internet]) --> NACL
    subgraph SUBNET["Subnet (NACL = stateless, subnet-level)"]
      NACL[Network ACL<br/>numbered rules, allow+deny<br/>must allow ephemeral 1024-65535]
      subgraph INST["Instance"]
        SG[Security Group<br/>stateful, allow-only]
        APP[App]
      end
      NACL --> SG --> APP
    end
    FL[VPC Flow Log] -. observes ACCEPT/REJECT .-> SUBNET
    FL --> CW[(CloudWatch Logs / S3 / Firehose)]
```

## Key facts, limits & pricing

- **Ephemeral port range = `1024–65535`** (the safe superset to allow on a NACL for return traffic). OS-specific: Linux `32768–60999`, Windows 2008+ `49152–65535`, ELB/Lambda/NAT `1024–65535`. Direction: a server *receiving* requests allows ephemeral **outbound** (its reply → client's ephemeral port); an instance *initiating* outbound allows ephemeral **inbound** (the reply → its ephemeral port).
- **NACL rule numbers**: 1–32766 for custom rules, evaluated ascending, **first match wins**, plus an unremovable `*` rule that denies anything unmatched. Lower number = higher priority.
- **SG evaluation**: no order/precedence — all rules are a union of allows; if any allows the traffic, it's permitted; there are no denies.
- **One NACL per subnet, one SG-set per ENI.** A subnet uses the default NACL unless you associate a custom one. An ENI gets up to **5** security groups by default (raisable to 16).
- **Flow log fields (default v2):** `version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status`. Protocol numbers: **6 = TCP, 17 = UDP, 1 = ICMP**. Action = `ACCEPT`/`REJECT`.
- **Flow logs = metadata only, never payload.** (Payload/deep inspection = Network Firewall's job — a classic distractor.)
- **Flow log levels:** VPC, subnet, or ENI. **Destinations:** CloudWatch Logs, S3, Amazon Data Firehose (renamed from *Kinesis* Data Firehose — older material still uses the old name).
- **Not logged by flow logs:** traffic to the Amazon DNS server (custom DNS *is* logged), DHCP, the instance metadata endpoint `169.254.169.254`, the **Amazon Time Sync Service `169.254.169.123`**, Windows license activation, and the reserved VPC-router IP.
- **`max_aggregation_interval`**: 600s default, or 60s for faster records (set to 60 to see logs in ~2 min instead of ~10).
- **Network Firewall** ~$0.395/hr per firewall endpoint + data processing (⚠️ check current). SG/NACL are **free**. Flow logs cost only the destination storage/ingestion.

## Comparisons

### Security Group vs Network ACL (the exam's favorite table)

|   | Security Group | Network ACL |
|---|---|---|
| Level | Instance / ENI | Subnet |
| State | **Stateful** (return traffic auto-allowed) | **Stateless** (must allow return traffic explicitly) |
| Rules | **Allow only** | **Allow and deny** |
| Evaluation | All rules, union of allows | Numbered, low→high, **first match wins** |
| Default (the auto-created one) | Self-referencing inbound + allow-all outbound | Allow all in & out |
| Default (a NEW custom one) | Deny all inbound, allow all outbound | **Deny all** in & out |
| Source can be | CIDR **or another SG** | CIDR only |
| Ephemeral ports | Handled automatically (stateful) | **You must open `1024–65535`** |
| Blocks a specific IP? | **No** (can't deny) | **Yes** (explicit deny) |

### Where each layer sits

| Layer | Scope | Inspects | Can deny? | Cost |
|---|---|---|---|---|
| Security Group | ENI | IP + port (L3/L4) | No (allow-only) | Free |
| Network ACL | Subnet | IP + port (L3/L4) | Yes | Free |
| Network Firewall | VPC perimeter (firewall subnet) | **Payload / domain / protocol (L3–L7, IPS)** | Yes | ~$0.395/hr |

## Worked examples

> [!example] Worked example — reading real flow logs from this build (ACCEPT vs REJECT)
> A throwaway instance (`10.0.0.43`) in the public subnet generated these actual records:
> ```
> 185.125.188.59 → 10.0.0.43  443 → 50908  TCP  ACCEPT   (Canonical HTTPS reply; ephemeral inbound allowed)
> 167.94.145.20  → 10.0.0.43  46084 → 993  TCP  REJECT   (internet scanner hitting IMAPS; SG allows only 22)
> 10.0.0.43 → 23.186.168.125  41532 → 123  UDP  REJECT   (instance's NTP blocked by the TCP-only NACL)
> ```
> Reading them: **REJECT + inbound + a port you never opened** = your firewall doing its job (that `167.94.145.20` is a real internet research scanner — this noise hits every public IP constantly). **REJECT + outbound + a port your app needs** = *your own* rule is too strict → the bug. Troubleshooting flow: grep `REJECT`, read the `dstport`, decide "intended block or my mistake."

> [!failure] Failure mode — the stateless NACL that "half works"
> You add a NACL allowing inbound HTTP 80 so users reach a web server, but pages hang. The SG is fine. Cause: the NACL is **stateless**, so the server's *reply* (going back out to the client's ephemeral port) needs its own **outbound** rule for `1024–65535` — which you didn't add, so the response is dropped by the implicit `* deny`. Inbound worked, outbound reply died, connection half-opened. Fix: add the ephemeral outbound allow. **This is the single most common NACL mistake and a guaranteed exam question.** (Its sibling bit us live: a *TCP-only* NACL blocked the instance's **UDP 53 DNS and UDP 123 NTP**, showing up as outbound `REJECT` in the flow logs above.)

> [!example] Worked example — when SG can't do the job (block one bad IP)
> A single IP is scraping your app abusively and you must block it at the **subnet** level regardless of instance SGs. A security group **can't** — it's allow-only. You add a NACL rule: `rule_no 100, action deny, cidr 203.0.113.50/32`, numbered **below** your allow rules so first-match-wins blocks it before any allow is considered. This is *the* reason NACLs exist alongside SGs — explicit deny + subnet-wide reach. (Real-world caveat: for app-layer / scaled blocking you'd reach for AWS WAF or Network Firewall; a NACL is the blunt L3/L4 instrument.)

## The Terraform I wrote

Code: [`05-vpc/security.tf`](../05-vpc/security.tf) (NACL) + [`05-vpc/flow-logs.tf`](../05-vpc/flow-logs.tf)

- NACL on the public subnets: `#100 deny 203.0.113.50/32` (proves precedence), `#110/120` allow 80/443, `#130` allow SSH 22 from my `/32`, `#140` + egress `#120` allow ephemeral `1024–65535`. Inline `ingress`/`egress` blocks.
- Flow log → CloudWatch: `aws_cloudwatch_log_group` + an IAM **service role** (`vpc-flow-logs.amazonaws.com` trust policy + `logs:*` permissions) + `aws_flow_log` (`traffic_type = "ALL"`, `max_aggregation_interval = 60`). Verified by reading real ACCEPT/REJECT records.

Two things learned the hard way:
- **Trust-vs-permissions swap:** first wired `assume_role_policy` to the *permissions* document instead of the trust document → would fail apply with `MalformedPolicyDocument`. `validate` passed (valid reference, wrong meaning); **TFLint's `terraform_unused_declarations`** would flag the now-unused trust doc — logic errors need lint + plan-reading, not `validate`.
- **TCP-only NACL** silently blocks UDP DNS/NTP — saw it as outbound `REJECT` in the flow logs.

> [!warning] Trap — "make the NACL match the SG rules and you're done"
> No — the NACL is stateless, so it needs the **ephemeral return rule** the SG never required. Mirroring SG rules onto a NACL without ephemeral ports is the guaranteed-to-break configuration.

> [!warning] Trap — "use flow logs to see what data was exfiltrated"
> Flow logs are **metadata only** — IPs, ports, bytes, ACCEPT/REJECT. They never show payload. Payload/domain/deep inspection = **Network Firewall** (or VPC Traffic Mirroring for packet capture). Common distractor.

> [!warning] Trap — "a higher NACL rule number can override a lower deny"
> No — **first match wins, low number first**. A `deny` at #100 is final; #200 allow never gets evaluated for that packet.

> [!example]- Recreate-from-memory drill
> On a public subnet: write a NACL that (a) denies one specific IP, (b) allows inbound HTTP/HTTPS from anywhere, (c) allows SSH only from your IP, (d) allows the ephemeral return range in the correct direction(s). Then add a VPC flow log to CloudWatch with a 60s aggregation interval and the required IAM service role. Confirm you can predict which of your rules blocks a packet from the denied IP and why.
> > [!success]- Reference solution
> > See `05-vpc/security.tf` + `flow-logs.tf`. Gotchas: deny rule gets the **lowest** number; ephemeral `1024–65535` on **both** egress (server replies) and ingress (returns for instance-initiated); flow-log role trusts `vpc-flow-logs.amazonaws.com`.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Trust policy vs permissions policy (again)** — wired the permissions doc into `assume_role_policy`. The [[01-iam]] distinction keeps biting; trust = who assumes, permissions = what they can do.
- [ ] **Stateless NACL ephemeral return ports** — knew the *logic* but not the range (`1024–65535`); and a TCP-only NACL silently kills UDP DNS/NTP.
- [ ] **`validate` ≠ correct** — it passes on logic errors (wrong-but-valid references). Need TFLint (`unused_declarations`) + plan-reading to catch them.
- [ ] **Flow logs = metadata, not payload** — don't confuse with Network Firewall / Traffic Mirroring.
- [ ] **VPC Flow Logs details** (had forgotten the topic): fields, levels VPC/subnet/ENI, destinations CloudWatch/S3/Firehose, excluded traffic.

## 🔗 Docs

- [Security groups](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html) / [Network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html) — incl. ephemeral ports + default behaviors
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html) — fields, levels, destinations, excluded traffic; verified 2026-07
- [Flow log record fields](https://docs.aws.amazon.com/vpc/latest/userguide/flow-log-records.html)
- [AWS Network Firewall — what is it](https://docs.aws.amazon.com/network-firewall/latest/developerguide/what-is-aws-network-firewall.html) — Suricata IPS, firewall subnet, domain filtering, deep packet inspection; verified 2026-07
- [Terraform `aws_network_acl`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) / [`aws_flow_log`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log)

---
**Cards for this topic:** [[cards/05-vpc-security-cards]]
