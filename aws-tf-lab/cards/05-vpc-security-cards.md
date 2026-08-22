---
topic: 05-vpc-security
domain: secure
related_note: 05-vpc-security
tags: [flashcards/vpc]
---

# Cards for [[05-vpc-security]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

Security Group vs NACL — state, level, and rule types?
?
Security Group: stateful, instance/ENI-level, ALLOW-only. NACL: stateless, subnet-level, ALLOW and DENY. Stateful means the SG auto-allows return traffic; stateless means the NACL needs explicit rules for the return direction too.

How are NACL rules evaluated, and what wins?
?
Numbered rules evaluated in ASCENDING order, FIRST MATCH WINS (lower number = higher priority), plus an unremovable `*` rule that denies anything unmatched. So a deny at #100 beats an allow at #200. Security groups have no order — all rules are a union of allows.

What's the ephemeral port range you must allow on a NACL, and why?
?
1024–65535 (the safe superset). Because a NACL is stateless, the return traffic needs its own rule: a server receiving requests must allow ephemeral OUTBOUND (its reply goes to the client's ephemeral port); an instance initiating outbound must allow ephemeral INBOUND. OS-specific: Linux 32768–60999, Windows 2008+ 49152–65535, ELB/Lambda/NAT 1024–65535.

Default NACL vs a new custom NACL — behavior?
?
Default NACL (AWS auto-created): allows ALL traffic in and out. A NEW custom NACL you create: DENIES all in and out until you add numbered rules. Opposite defaults — a classic trap.

When must you use a NACL instead of (or with) a security group?
?
When you need to explicitly DENY (e.g. block a specific bad IP/CIDR) — SGs are allow-only and can't deny — or when you need a subnet-wide guardrail independent of who manages the instances. SGs handle the 95% allow-case; NACLs add explicit deny + subnet-level reach + defense-in-depth.

Can a security group block a specific IP address? Why or why not?
?
No. Security groups are allow-only with an implicit deny for everything unlisted — there's no explicit deny rule, so you can't single out one IP to block while allowing others. Use a NACL deny rule (or AWS WAF / Network Firewall at higher layers).

What do VPC Flow Logs capture, and what do they NOT capture?
?
They capture connection METADATA per flow: source/dest IP, source/dest port, protocol, packets, bytes, start/end time, and the ACTION (ACCEPT or REJECT). They do NOT capture the packet payload/contents. Payload/deep inspection is Network Firewall's job (or Traffic Mirroring for packet capture).

At what levels can you attach a VPC Flow Log, and where can it publish?
?
Levels: VPC, subnet, or ENI (network interface). Destinations: CloudWatch Logs, S3, or Amazon Data Firehose (renamed from Kinesis Data Firehose — older material still says Kinesis).

In a flow log record, what do protocol numbers 6, 17, and 1 mean?
?
6 = TCP, 17 = UDP, 1 = ICMP. (Record layout: version account-id eni-id srcaddr dstaddr srcport dstport protocol packets bytes start end ACTION log-status.)

Name traffic that VPC Flow Logs do NOT record.
?
Traffic to the Amazon DNS server (custom DNS IS logged), DHCP, the instance metadata endpoint 169.254.169.254, the Amazon Time Sync Service 169.254.169.123, Windows license activation, and the reserved VPC-router IP.

How do you troubleshoot "traffic is being blocked" with flow logs?
?
Filter for REJECT records and read the dstport. REJECT + inbound + a port you never opened = your SG/NACL working as intended (e.g. internet scanners). REJECT + outbound + a port your app needs (53, 123, ...) = your OWN SG/NACL is too restrictive — that's the bug to fix.

What is AWS Network Firewall and how does it differ from SG/NACL?
?
A managed, stateful network firewall + intrusion prevention system (IPS, uses Suricata) for a VPC. It does deep packet inspection, domain-name filtering, and stateful protocol detection (e.g. filter HTTPS regardless of port) — L3–L7. SGs and NACLs only allow/deny by IP+port (L3/L4). Network Firewall runs in a dedicated firewall subnet with route tables redirecting traffic through it, and costs ~$0.395/hr (SG/NACL are free).

Why did `terraform validate` pass on a trust-policy-vs-permissions-policy swap?
?
validate checks syntax, types, and that references resolve — not whether you referenced the RIGHT document. Pointing assume_role_policy at the permissions doc is a valid reference (logic error, not syntax error), so validate passes; it fails at apply (MalformedPolicyDocument). TFLint's terraform_unused_declarations flags the now-unused trust doc; reading the plan shows the wrong JSON.
