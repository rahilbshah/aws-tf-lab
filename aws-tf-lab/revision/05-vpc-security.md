---
topic: 05-vpc-security
type: revision
source: 05-vpc-security
tags: [revision, generated]
---

# Revision — 05.2 – VPC Security (SG, NACL, Flow Logs, Network Firewall)

> [!abstract] Night-before read · ~6 min · self-contained
> Everything you need is here — no need to jump back mid-revision.
> Full teaching explanations, Terraform and diagrams: **[[05-vpc-security]]**
> *Generated from the note by `_scripts/build_revision.py` — do not edit.*
## The shape of it

> [!info] Exam TL;DR
> - **Security Group** = stateful, instance/ENI-level, **allow-only** (implicit deny for the rest), all rules evaluated together. Return traffic is auto-allowed (stateful).
> - **NACL** = stateless, subnet-level, **allow AND deny**, rules **numbered & evaluated low→high, first match wins**. You must open **both directions** *and* the **ephemeral return ports `1024–65535`** yourself.
> - **Default flip:** default NACL = allow-all; a **new custom NACL = deny-all**. (SGs: new SG denies inbound; default SG self-references.)
> - **Use a NACL when** you need an explicit **DENY** (block an IP/CIDR) or a **subnet-wide guardrail** — the two things an SG fundamentally can't do.
> - **Flow Logs** capture connection **metadata** + **ACCEPT/REJECT** — never payload. Attach at **VPC / subnet / ENI**; publish to **CloudWatch Logs / S3 / Kinesis Firehose**.
> - **Network Firewall** = managed, stateful **IPS (Suricata)** with deep packet inspection + **domain filtering**; lives in a **dedicated firewall subnet** with route tables sending traffic through it. Far beyond SG/NACL (which are just IP/port allow-deny).

## Facts, limits & pricing

- **Ephemeral port range = `1024–65535`** (the safe superset to allow on a NACL for return traffic). OS-specific: Linux `32768–60999`, Windows 2008+ `49152–65535`, ELB/Lambda/NAT `1024–65535`. Direction: a server *receiving* requests allows ephemeral **outbound** (its reply → client's ephemeral port); an instance *initiating* outbound allows ephemeral **inbound** (the reply → its ephemeral port).
- **NACL rule numbers**: 1–32766 for custom rules, evaluated ascending, **first match wins**, plus an unremovable `*` rule that denies anything unmatched. Lower number = higher priority.
- **SG evaluation**: no order/precedence — all rules are a union of allows; if any allows the traffic, it's permitted; there are no denies.
- **One NACL per subnet, one SG-set per ENI.** A subnet uses the default NACL unless you associate a custom one. An instance can have up to (quota) SGs.
- **Flow log fields (default v2):** `version account-id eni-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status`. Protocol numbers: **6 = TCP, 17 = UDP, 1 = ICMP**. Action = `ACCEPT`/`REJECT`.
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

## Traps & failure modes

> [!warning] Trap — "make the NACL match the SG rules and you're done"
> No — the NACL is stateless, so it needs the **ephemeral return rule** the SG never required. Mirroring SG rules onto a NACL without ephemeral ports is the guaranteed-to-break configuration.

> [!warning] Trap — "use flow logs to see what data was exfiltrated"
> Flow logs are **metadata only** — IPs, ports, bytes, ACCEPT/REJECT. They never show payload. Payload/domain/deep inspection = **Network Firewall** (or VPC Traffic Mirroring for packet capture). Common distractor.

> [!warning] Trap — "a higher NACL rule number can override a lower deny"
> No — **first match wins, low number first**. A `deny` at #100 is final; #200 allow never gets evaluated for that packet.
