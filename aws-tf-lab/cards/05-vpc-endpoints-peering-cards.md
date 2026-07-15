---
topic: 05-vpc-endpoints-peering
domain: secure
related_note: 05-vpc-endpoints-peering
tags: [flashcards/vpc]
---

# Cards for [[05-vpc-endpoints-peering]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What are the two types of VPC endpoint and how do they differ?
?
Gateway endpoint: a route-table entry (prefix-list route), for S3 and DynamoDB ONLY, free. Interface endpoint: an ENI with a private IP in your subnet, powered by PrivateLink, for almost every other service, ~$0.01/hr/AZ + data. Decision: S3/DynamoDB → gateway (free); anything else → interface.

Which AWS services use a gateway endpoint?
?
Only S3 and DynamoDB. Every other service uses an interface endpoint (PrivateLink). "Private access to SQS/KMS/Secrets Manager/etc." → interface endpoint, not gateway.

Can you reach a gateway endpoint from a peered VPC, VPN, or Direct Connect?
?
No — gateway endpoints work only from WITHIN the same VPC (they're route-table based). If you need private S3 access from a peered VPC or over VPN/DX, use an INTERFACE endpoint, which IS reachable across those connections.

What does a VPC endpoint give you that going through a NAT gateway doesn't?
?
Traffic stays on the AWS private backbone (never the public internet), you can have a fully-private subnet with no internet path, and (for gateway endpoints) it's free — removing the NAT gateway's hourly + per-GB cost if S3/DynamoDB was the only reason for it. Plus endpoint policies to restrict access.

What are the two hard limitations of VPC peering?
?
1) Non-transitive: if A–B and B–C are peered, A CANNOT reach C through B — every pair needs its own peering. 2) No overlapping CIDRs between the two VPCs. Also: no edge-to-edge routing (can't use a peer's IGW/NAT/VPN), and you must update route tables on BOTH sides.

When you peer two VPCs, which CIDR does each side's route point to?
?
Each side routes to the OTHER VPC's CIDR via the peering connection. On VPC A's route table: destination = B's CIDR. On VPC B's route table: destination = A's CIDR. Forgetting one side (or swapping them) makes traffic silently blackhole.

How many peering connections does a full mesh of N VPCs need?
?
N(N-1)/2. So 5 VPCs = 10, 6 = 15, 10 = 45 — it grows O(N²). Combined with non-transitivity, a full mesh becomes unmanageable, which is why Transit Gateway exists.

What is a Transit Gateway and what problem does it solve?
?
A regional hub-and-spoke router. Instead of an N(N-1)/2 peering mesh, each VPC gets ONE attachment to the TGW, and connectivity is TRANSITIVE (VPCs on the same TGW reach each other through it). On-prem (VPN/Direct Connect) attaches to the same hub. Scales to thousands of VPCs with route tables for segmentation. Trigger: "many VPCs / hybrid at scale, simplify connectivity."

Is VPC peering cross-account and cross-region capable?
?
Yes — peering works across accounts and across regions. Cross-account requires the accepter side to accept (aws_vpc_peering_connection_accepter); same-account+region can use auto_accept = true.

What is AWS PrivateLink?
?
The technology behind interface endpoints: it exposes a service via an ENI with a private IP in your VPC, so traffic never leaves the AWS network. It also lets you expose YOUR OWN service (via an endpoint service backed by an NLB) privately to other VPCs/accounts.

What's the cost difference between gateway and interface endpoints?
?
Gateway endpoints (S3/DynamoDB) are FREE. Interface endpoints cost ~$0.01/hr per endpoint per AZ + ~$0.01/GB data processed. So for S3/DynamoDB always prefer the gateway endpoint on cost.

How is an interface endpoint secured and how is it reached?
?
Secured by a security group (it's an ENI). Reached via private DNS: with private_dns_enabled, the service's normal hostname resolves to the endpoint's private IP, so your app code needs no change. Both endpoint types also support endpoint policies to restrict actions/resources.
