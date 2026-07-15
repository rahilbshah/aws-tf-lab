---
topic: 05-vpc-endpoints-peering
domain: secure
status: reviewed
services: [VPC Endpoints, PrivateLink, VPC Peering, Transit Gateway]
related: [05-vpc, 05-vpc-core, 05-vpc-security, 05-vpc-hybrid]
cards: cards/05-vpc-endpoints-peering-cards
tags: [topic, domain/secure]
---

# 05.3 – VPC Endpoints & Peering (+ Transit Gateway)

Two ways to keep traffic off the public internet: **endpoints** reach *AWS services* privately; **peering / Transit Gateway** connect *VPCs* privately. Part of [[05-vpc]].

> [!info] Exam TL;DR
> - **Gateway endpoint** = a **route-table** entry for **S3 & DynamoDB only**, **free**. Lets a fully-private subnet reach S3/DynamoDB with no NAT/IGW.
> - **Interface endpoint** = an **ENI with a private IP** in your subnet, powered by **PrivateLink**, for **almost every other service**, **~$0.01/hr/AZ + data**. Reachable over peering/VPN/DX (gateway endpoints are **not**).
> - **VPC peering** = private 1-to-1 link between two VPCs. **Non-transitive** (A–B + B–C ≠ A–C) and **no overlapping CIDRs**. Cross-account & cross-region OK. Update route tables **on both sides**.
> - **Full mesh of N VPCs = N(N-1)/2 peerings** → explodes. **Transit Gateway** = hub-and-spoke: each VPC gets **one attachment**, connectivity is **transitive**, and on-prem (VPN/DX) attaches to the same hub. Scales to thousands.
> - Decision: **S3/DynamoDB privately → gateway endpoint (free)**; other service → interface endpoint; **2 VPCs → peering**; **many VPCs / hybrid at scale → Transit Gateway**.

## Concept (plain English)

By default, reaching an AWS service (like S3) from your VPC goes over the public internet — which forces a NAT/IGW path and leaves the subnet internet-connected. **VPC endpoints** fix that: they give you a private on-ramp to the service over AWS's backbone, so a fully-private subnet can reach S3 or SQS without ever touching the internet. There are two kinds — gateway (route-based, S3/DynamoDB, free) and interface (an ENI, PrivateLink, most services, paid). Separately, **peering** and **Transit Gateway** connect *VPCs* to each other privately: peering is a simple 1-to-1 link that doesn't scale (non-transitive, quadratic mesh), and Transit Gateway is the hub-and-spoke router that replaces the mesh once you have more than a couple of VPCs or need to fold in on-prem.

## AWS console ↔ Terraform map

| Concept | Terraform | Notes |
|---|---|---|
| Gateway endpoint (S3/DynamoDB) | `aws_vpc_endpoint` (`vpc_endpoint_type = "Gateway"`, `route_table_ids`) | Injects an S3/DynamoDB prefix-list route. Free. |
| Interface endpoint (PrivateLink) | `aws_vpc_endpoint` (`type = "Interface"`, `subnet_ids`, `security_group_ids`, `private_dns_enabled`) | ENI per AZ; the SG controls who can reach it. Costs hourly. |
| Expose your own service privately | `aws_vpc_endpoint_service` (+ NLB) | The "endpoint service" side of PrivateLink. |
| VPC peering | `aws_vpc_peering_connection` (+ `_accepter` if cross-account) | `auto_accept = true` only same-account+region. |
| Peering routes | `aws_route` on **both** route tables | Each side routes to the **other** VPC's CIDR via the `vpc_peering_connection_id`. |
| Transit Gateway | `aws_ec2_transit_gateway` + `_vpc_attachment` + `_route_table` | *Conceptual here.* Hub; attachments per VPC/VPN/DX. |

## Architecture diagram

```mermaid
flowchart TB
    subgraph V["Your VPC (private subnet)"]
      EC2[Instance]
      IE[Interface Endpoint ENI<br/>private IP - PrivateLink]
    end
    EC2 -->|route table -> prefix list| GE([S3 Gateway Endpoint])
    GE --> S3[(S3 / DynamoDB - free)]
    EC2 -->|private DNS -> ENI IP| IE --> SVC[SQS / KMS / etc.]

    subgraph MESH["Peering vs Transit Gateway"]
      direction LR
      A[VPC A]<-->|pcx| B[VPC B]
      A2[VPC A] --- TGW{{Transit Gateway<br/>hub, transitive}}
      B2[VPC B] --- TGW
      C2[VPC C] --- TGW
      ONP[On-prem VPN/DX] --- TGW
    end
```

## Key facts, limits & pricing

- **Gateway endpoints: S3 and DynamoDB only. Free.** Route-table based (a prefix-list route `pl-xxxx → vpce-xxxx`). **Cannot** be accessed from a peered VPC, VPN, or Direct Connect — only from within the same VPC.
- **Interface endpoints (PrivateLink):** an **ENI with a private IP** in each chosen subnet, for most AWS services + partner/your-own services. **Reachable across peering / VPN / Direct Connect** (unlike gateway). Uses **private DNS** so the normal service hostname resolves to the ENI. ~**$0.01/hr per endpoint per AZ + ~$0.01/GB** — ⚠️ check current pricing. Secured by a **security group**.
- **Endpoint policies:** both types support a resource-style policy to restrict which resources/actions the endpoint allows (default = full access).
- **VPC peering:** private, uses AWS backbone, **cross-account and cross-region** supported. Limits: **non-transitive**, **no overlapping CIDRs**, **no edge-to-edge routing** (you can't use a peer's IGW, NAT, VPN, or endpoints through the peering). Both route tables must be updated.
- **Mesh math:** a full mesh of N VPCs needs **N(N-1)/2** peering connections (5→10, 6→15, 10→45). O(N²).
- **Transit Gateway:** regional hub; each VPC/VPN/DX = **one attachment**; connectivity is **transitive**; supports **TGW route tables** for segmentation and **inter-region TGW peering**. Scales to thousands of attachments. Costs: **per-attachment/hour + per-GB data**. Overkill for 2–3 VPCs; the answer for many/at-scale/hybrid.

## Comparisons

### Gateway vs Interface endpoint

|   | Gateway endpoint | Interface endpoint |
|---|---|---|
| Mechanism | Route-table prefix-list route | ENI with private IP (PrivateLink) |
| Services | **S3, DynamoDB only** | Most AWS services + partner/custom |
| Cost | **Free** | ~$0.01/hr/AZ + data |
| Cross VPC/VPN/DX access | **No** | **Yes** |
| DNS | (route-based, no DNS change) | Private DNS → ENI IP |
| Secured by | Endpoint policy | Endpoint policy **+ security group** |

### VPC Peering vs Transit Gateway

|   | VPC Peering | Transit Gateway |
|---|---|---|
| Topology | 1-to-1 point-to-point | Hub-and-spoke |
| Transitive? | **No** | **Yes** |
| Connections for N VPCs | **N(N-1)/2** (mesh) | **N** attachments |
| On-prem (VPN/DX) | Not through peering | Attaches to the hub |
| Cost | Free (pay data) | Per-attachment/hr + data |
| Use when | 2 (few) VPCs, simple | Many VPCs / hybrid / at scale |

## Worked examples

> [!example] Worked example — a fully-private subnet that still reaches S3 (no NAT bill)
> A batch worker in a private subnet reads/writes objects to S3 all day. The naive setup routes it through a **NAT gateway** — which bills hourly *and* per-GB, and the per-GB S3 traffic can dwarf the hourly cost. Swap in an **S3 gateway endpoint**: add it to the private route table, and S3-bound traffic now goes straight over the AWS backbone via the injected prefix-list route — **free**, and you can delete the NAT gateway entirely if S3 was its only reason to exist. This is a top real-world **cost-optimization** win and a common exam answer ("reduce data-transfer cost for S3 access from private instances → gateway endpoint").

> [!failure] Failure mode — assuming peering is transitive (the hub that isn't)
> You peer a central "shared services" VPC to VPC-A and to VPC-B, expecting A and B to talk *through* the shared VPC. They can't — **peering is non-transitive**, so A↔shared and B↔shared give you **nothing** between A and B. Teams discover this when A's traffic to B silently blackholes despite "everything being peered." Fixes: peer A↔B directly (another connection — and the mesh grows), or replace the whole thing with a **Transit Gateway** where transitivity is built in. This non-transitivity is *the* reason TGW exists and a guaranteed exam distractor.

> [!example] Worked example — 4 VPCs today, 12 next quarter → Transit Gateway
> A company has 4 VPCs (prod/staging/dev/shared) fully peered: N(N-1)/2 = **6** connections, each with routes on both sides. Manageable. Then acquisitions push it toward 12 VPCs → **66** peering connections and a route-table nightmare. Migrating to a **Transit Gateway** collapses it to **12 attachments** (one per VPC), gives transitive any-to-any (or segmented via TGW route tables), and lets the on-prem Direct Connect attach to the same hub. The trigger phrase — "growing number of VPCs, simplify connectivity, connect on-prem" — is always TGW.

## The Terraform I wrote

Code: [`05-vpc/endpoints.tf`](../05-vpc/endpoints.tf) + [`05-vpc/peering.tf`](../05-vpc/peering.tf)

- **S3 gateway endpoint**: `aws_vpc_endpoint` (Gateway, `service_name = com.amazonaws.us-east-1.s3`, `route_table_ids = [private-rt]`). Verified the injected `pl-xxxx (S3) → vpce-xxxx` route in the private route table.
- **Peering**: a second VPC (`10.1.0.0/16`, non-overlapping), `aws_vpc_peering_connection` (`auto_accept = true`), and **two `aws_route`s** — main-side → peer CIDR, peer-side → main CIDR, each via the connection. Verified status **Active** and both route tables carrying the cross-VPC route.
- Got the **route directions right** (each side routes to the *other's* CIDR — the common swap mistake) and used `aws_vpc.peer.main_route_table_id` to route on the peer's auto-created main RT.

> [!warning] Trap — "use a gateway endpoint for SQS/KMS/etc."
> Gateway endpoints only exist for **S3 and DynamoDB**. Every other service uses an **interface endpoint (PrivateLink)**. "Private access to SQS/KMS/Secrets Manager" → interface endpoint, not gateway.

> [!warning] Trap — "reach the S3 gateway endpoint from a peered VPC / on-prem"
> No. Gateway endpoints work **only within the same VPC**. If you need S3 access from a peered VPC or over VPN/DX, you use an **interface endpoint** (which *is* reachable across those).

> [!warning] Trap — "peering scales fine, just add connections"
> Full mesh is **N(N-1)/2** and non-transitive — it explodes past a few VPCs. The intended answer for "many VPCs" is **Transit Gateway**, not more peerings.

> [!example]- Recreate-from-memory drill
> On an existing VPC: (a) add an S3 gateway endpoint to the private route table and confirm the prefix-list route appears; (b) create a second VPC with a non-overlapping CIDR, peer them, and add the correct route on each side. Predict, before applying, which CIDR each route's destination should be.
> > [!success]- Reference solution
> > See `05-vpc/endpoints.tf` + `peering.tf`. Key: gateway endpoint `route_table_ids`; peering routes each target the **other** VPC's CIDR; CIDRs must not overlap; `auto_accept` only for same account+region.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **Gateway vs interface endpoint** — which is which, S3/DynamoDB-only for gateway, PrivateLink/ENI for interface, and gateway-not-reachable-cross-VPC. (Fuzzy at orient.)
- [ ] **Peering is non-transitive + no CIDR overlap** — forgot the peering limits entirely at orient; these are the two most-tested facts.
- [ ] **Transit Gateway = hub-and-spoke fix for the N(N-1)/2 mesh** — knew the mesh math but not the TGW mechanism.
- [ ] **"Which endpoint for which service"** decision (S3/DynamoDB → gateway/free; everything else → interface/paid).

## 🔗 Docs

- [Gateway endpoints (S3/DynamoDB)](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html)
- [Interface endpoints / AWS PrivateLink](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html)
- [VPC peering — what it is + limitations](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html)
- [Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
- [Terraform `aws_vpc_endpoint`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) / [`aws_vpc_peering_connection`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection)

---
**Cards for this topic:** [[cards/05-vpc-endpoints-peering-cards]]
