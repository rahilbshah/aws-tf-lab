---
decision: networking
question: How should these things reach each other?
spans: [05-vpc-core, 05-vpc-endpoints-peering, 05-vpc-hybrid, 05-vpc-security]
tags: [decision, domain/secure]
---

# How should these things reach each other?

The notes explain each connectivity option. This routes you to one. Name the two ends
first — that alone deletes most of the menu — then answer the one axis that section asks.

## 1. What is at each end?

| From | To | Go to |
|---|---|---|
| a subnet | the internet | §2 |
| a subnet | an AWS service (S3, SQS, KMS…) | §3 |
| a VPC | another VPC | §4 |
| a VPC | a data centre you own | §5 |
| one employee's laptop | a VPC | **Client VPN**. Whole networks are §5 |

Then §6, once a path exists: who is allowed to use it.

## 2. Subnet ↔ internet

The axis is **which side opens the conversation**, not which subnet it is.

- The internet must be able to *start* it → **Internet Gateway** + a public IP on the instance. Both halves, or it isn't public.
- Outbound only, IPv4 → **NAT gateway**, living in a public subnet.
- Outbound only, IPv6 → **egress-only Internet Gateway**. IPv6 is globally routable, so there is nothing to translate.
- Outbound, and the box must double as a bastion or be as cheap as possible → **NAT instance**. Otherwise never.

If it's a NAT, one follow-up: **how much does losing an AZ matter?** One NAT for the whole
VPC is a single point of failure with a cross-AZ bill attached; one per AZ is production.

↳ [[05-vpc-core#There is no public subnet checkbox]] · [[05-vpc-core#Why the NAT gateway has to live in a public subnet]] · [[05-vpc-core#IGW vs NAT Gateway vs Egress-only IGW]]

## 3. Subnet ↔ an AWS service, privately

Two questions, and the first overrides the second.

**Is the caller inside this VPC?** Traffic arriving over peering, VPN or Direct Connect needs
an **interface endpoint** — a gateway endpoint is usable only from within the VPC that owns
the route table, whatever the service is.

**Is the service S3 or DynamoDB?** Yes → **gateway endpoint**: a route-table entry, free, and
it removes the NAT charge on that traffic outright. Anything else → interface endpoint.

↳ [[05-vpc-endpoints-peering#Gateway vs Interface endpoint]]

## 4. VPC ↔ VPC

The axis is **will anything else ever need to reach through this link?**

- Exactly two VPCs, and only those two → **VPC peering**. Free; routes on both sides.
- A third network already wants in, the count is growing, or on-prem must join the same fabric → **Transit Gateway**: one attachment per network, and transitive.

Don't route this on how many VPCs exist today: peering is non-transitive and its wiring grows
O(N²), so a wrong answer here is paid for later, unpicking a mesh. Overlapping CIDRs settle
it outright — peering refuses them.

↳ [[05-vpc-endpoints-peering#Why peering never becomes a hub]] · [[05-vpc-endpoints-peering#VPC Peering vs Transit Gateway]]

## 5. VPC ↔ your data centre

Ask in this order. The first answer that applies wins.

1. **When must it work?** *Quickly*, *temporary*, *by next week* → **Site-to-Site VPN**, however much throughput the requirement also waves around. DX is weeks to months of physical installation.
2. **Private *and* encrypted?** → **VPN over Direct Connect**. DX alone is a private path, not a secret one.
3. **Is consistent throughput or predictable latency the real requirement?** → **Direct Connect**. Below 1 Gbps means a *hosted* connection through a partner.
4. **One circuit reaching VPCs in several regions?** → **Direct Connect Gateway** — but it is non-transitive, a way in rather than a way across, so if those VPCs also need each other, §4 applies on top.

↳ [[05-vpc-hybrid#The calendar usually decides, not the bandwidth]] · [[05-vpc-hybrid#Private is not the same as encrypted]] · [[05-vpc-hybrid#One circuit, many VPCs — and the limit of that]]

## 6. Now: who is allowed on the path?

- **Default** → a **security group** per instance. Stateful, and its source can be another security group — how you say "only the app tier" without naming an address.
- **You must say *no* to one address, or need a guardrail that binds whoever launches the instance** → a **network ACL**: the only one that can deny, the only one on the subnet.
- **The rule is about a domain name or the packet's contents** → **Network Firewall**. It only inspects what your route tables send into its subnet.
- **The path exists, something is dropped, and you can't see why** → **flow logs**: ACCEPT/REJECT per connection. If the question is *what data left*, they can't answer it.

↳ [[05-vpc-security#Security Group vs Network ACL (the exam's favorite table)]] · [[05-vpc-security#Where each layer sits]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **Buying a NAT gateway when a gateway endpoint was the answer.** If S3 or DynamoDB is the
  only reason that subnet needs egress, the endpoint is free and replaces the NAT entirely.
- **Choosing a gateway endpoint for a peered or on-prem caller.** The service matches, the
  reachability doesn't. Private access across a boundary is always the interface endpoint.
- **Expecting a peer to borrow your exits.** No edge-to-edge routing: a peered VPC can't use
  your IGW, NAT, VPN or endpoints — the gateway-endpoint limit seen from the other side.
- **Treating a shared-services VPC as a hub.** Two peerings into it connect A and B to the
  middle, not to each other. A hub is a Transit Gateway or it is not a hub.
- **Picking Direct Connect to hit a date.** The throughput argument wins the design review
  and loses the launch. VPN now, cut over when the circuit lands, keep it as the backup.
- **Reading "private line" as "encrypted".** The cheap option is the encrypted one and the
  expensive one is not; they solve different problems.
- **Mirroring security-group rules onto a NACL and calling it done.** Stateless means the
  reply needs its own rule, on the ephemeral range, in the direction nobody expects.
