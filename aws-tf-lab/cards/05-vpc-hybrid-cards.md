---
topic: 05-vpc-hybrid
domain: secure
related_note: 05-vpc-hybrid
tags: [flashcards/vpc]
---

# Cards for [[05-vpc-hybrid]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What is a Site-to-Site VPN, and what medium + encryption does it use?
?
An AWS-managed IPsec VPN connecting your on-premises network to a VPC over the PUBLIC INTERNET, and it IS encrypted (IPsec). AWS provisions two tunnels for redundancy; supports static routes or BGP. Fast to set up (minutes-hours), cheap, but performance depends on the internet.

What are the AWS-side and on-prem-side endpoints of a Site-to-Site VPN?
?
AWS side: Virtual Private Gateway (VGW) attached to the VPC — or a Transit Gateway for many VPCs. On-prem side: Customer Gateway (CGW), a config object representing your physical router (its public IP + BGP ASN). VGW = AWS, CGW = on-prem — don't swap them.

Is AWS Direct Connect encrypted by default? How do you encrypt it?
?
NO — Direct Connect is a private dedicated line but is NOT encrypted by default (private ≠ encrypted). To encrypt DX traffic you run a Site-to-Site VPN OVER the Direct Connect (IPsec over a public VIF), or use MACsec on supported ports. This is the single most-tested DX nuance.

What is AWS Direct Connect, physically, and its main tradeoffs vs VPN?
?
A dedicated private physical fiber connection from your data center to an AWS Direct Connect location, bypassing the internet entirely. Pros: consistent low latency, guaranteed bandwidth, lower data-transfer cost at volume. Cons: expensive, and takes WEEKS-TO-MONTHS to provision (physical cross-connect). Speeds: 1/10/100 Gbps dedicated, sub-1 Gbps hosted.

VPN vs Direct Connect: which for "we need a connection quickly / temporarily"?
?
Site-to-Site VPN. It's up in minutes-to-hours. Direct Connect takes weeks-to-months to provision (physical circuit), so anything "fast," "temporary," or "this week" is always VPN.

VPN vs Direct Connect: which for "consistent high throughput and low latency (e.g. DB replication)"?
?
Direct Connect. Dedicated bandwidth + consistent low latency is exactly its value; a VPN's reliance on the public internet makes latency/bandwidth variable.

What is the cost-effective HA pattern for a Direct Connect connection?
?
Use a Site-to-Site VPN as the BACKUP/failover for the Direct Connect. If the DX line goes down, traffic fails over to the (much cheaper) VPN. For maximum resilience you'd instead use dual Direct Connect connections, but VPN-backup is the cost-effective answer.

What are the three Direct Connect Virtual Interface (VIF) types?
?
Private VIF → access one VPC (via a VGW) using private IPs. Public VIF → access AWS public services (S3, etc.) globally over public IPs. Transit VIF → access one or more Transit Gateways (via a Direct Connect Gateway).

What does a Direct Connect Gateway do?
?
It's a global object that lets ONE Direct Connect connection reach VPCs in MULTIPLE regions and accounts (a private VIF → DXGW → many VGWs; a transit VIF → DXGW → many TGWs). It is NOT transitive — VPCs reached via a DXGW can't talk to each other through it.

How do you connect many VPCs plus on-prem into one network at scale?
?
Transit Gateway as the regional hub (each VPC = one attachment), with Site-to-Site VPN and/or Direct Connect (via a transit VIF + DX Gateway) attaching the on-prem side to the same hub. TGW replaces the N(N-1)/2 peering mesh and is transitive.

Site-to-Site VPN vs Client VPN — what's the difference?
?
Site-to-Site VPN: connects a whole on-prem NETWORK to a VPC via IPsec (VGW + CGW). Client VPN: OpenVPN-based access for INDIVIDUAL remote users' devices (laptops). Different services — "connect employees' laptops remotely" = Client VPN; "connect the data center" = Site-to-Site.

What is VPN CloudHub?
?
A hub-and-spoke model over a Virtual Private Gateway that connects MULTIPLE on-premises branch offices to AWS (and to each other) using BGP — useful for primary or backup connectivity between remote sites.
