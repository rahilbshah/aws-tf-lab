---
topic: 05-vpc-core
domain: resilient
status: reviewed
services: [VPC, NAT Gateway, Internet Gateway]
related: [05-vpc, 05-vpc-security, 04-alb-asg, 02-ec2]
cards: cards/05-vpc-core-cards
tags: [topic, domain/resilient]
---

# 05.1 – VPC Core (subnets, routing, IGW, NAT)

The plumbing of a VPC: how you carve address space into public and private subnets and control which way traffic can flow. Part of the [[05-vpc]] topic.

> [!info] Exam TL;DR
> - A **subnet is public** iff **(1)** its route table has `0.0.0.0/0 → Internet Gateway` **and (2)** instances get a public IP (`map_public_ip_on_launch` or an EIP). Miss either and it's effectively private. There is no "public" checkbox.
> - **Route tables decide public vs private**, not the subnet itself. Any subnet not explicitly associated uses the VPC's **main route table**.
> - **IGW = bidirectional**, sits at the VPC edge, one per VPC. **NAT = outbound-only** for private subnets, lives *in a public subnet*, needs an EIP.
> - Creating a VPC auto-creates **3 defaults**: main route table, default NACL (allow-all), default SG (self-referencing). A **new custom** NACL denies all; a **new custom** SG denies inbound — opposite of the defaults.
> - Subnets are **AZ-scoped**; a VPC spans a region. AWS reserves **5 IPs per subnet** (first 4 + last 1).
> - **NAT gateway** = managed, AZ-scoped, one-per-AZ for HA, no SG. **NAT instance** = legacy EC2, needs source/dest-check off, has an SG, can double as a bastion.

## Concept (plain English)

A VPC is a private, region-scoped virtual network defined by a CIDR block (e.g. `10.0.0.0/16`). You slice it into subnets, each pinned to one Availability Zone. Whether a subnet is "public" is a consequence of routing: give its route table a default route to an Internet Gateway and hand its instances public IPs, and it's public; otherwise it's private. Private subnets can still reach *out* to the internet (updates, API calls) via a NAT gateway — but nothing on the internet can initiate a connection *in*, because NAT only tracks connections started from inside. This inbound/outbound asymmetry is the core of the public/private design.

## AWS console ↔ Terraform map

| Console / concept | Terraform | Key args / notes |
|---|---|---|
| Create a VPC | `aws_vpc` | `cidr_block`; set `enable_dns_hostnames = true` + `enable_dns_support = true` (public DNS + required for interface endpoints). |
| Look up AZ names | `data "aws_availability_zones" { state = "available" }` | `.names[0]`, `.names[1]` — don't hardcode `"us-east-1a"`. |
| Create a subnet | `aws_subnet` | `vpc_id`, `cidr_block`, `availability_zone`, `map_public_ip_on_launch` (true for public). |
| Internet gateway | `aws_internet_gateway` | `vpc_id` attaches it. One per VPC. |
| Route table | `aws_route_table` | Inline `route {}` OR separate `aws_route` — pick one, don't mix (drift). |
| Add a route | `aws_route` (or inline) | `gateway_id` (IGW), `nat_gateway_id` (NAT), `destination_cidr_block`. |
| Associate subnet ↔ RT | `aws_route_table_association` | One per (subnet, RT). Unassociated subnets fall back to the main RT. |
| Allocate EIP for NAT | `aws_eip` | `domain = "vpc"`. |
| NAT gateway | `aws_nat_gateway` | `allocation_id` (EIP) + `subnet_id` = a **public** subnet; `depends_on = [igw]` recommended. |
| Adopt the auto-created defaults | `aws_default_route_table` / `aws_default_network_acl` / `aws_default_security_group` | Manage (not create) the freebies AWS made. Optional; use to lock them down. |

## Architecture diagram

```mermaid
flowchart TB
    NET([Internet]) --- IGW[Internet Gateway<br/>bidirectional, VPC edge]
    IGW --- VPC
    subgraph VPC["VPC 10.0.0.0/16 (region)"]
      subgraph AZא["AZ us-east-1a"]
        PUBA["public-a 10.0.0.0/24<br/>RT: 0.0.0.0/0 -> IGW<br/>map_public_ip=true"]
        PRIA["private-a 10.0.10.0/24<br/>RT: 0.0.0.0/0 -> NAT"]
        NAT["NAT GW + EIP<br/>(in a PUBLIC subnet)"]
      end
      subgraph AZב["AZ us-east-1b"]
        PUBB["public-b 10.0.1.0/24"]
        PRIB["private-b 10.0.11.0/24"]
      end
      PUBA --- NAT
      PRIA -->|outbound only| NAT --> IGW
    end
```

## Key facts, limits & pricing

- **A subnet lives in exactly one AZ.** A VPC spans all AZs in its region. To be multi-AZ you create one subnet per AZ (that's why we build public-a/public-b, private-a/private-b).
- **The two conditions for "public"** (both required): route to IGW **and** a public IP on the instance. A subnet with an IGW route but no public IP, or a public IP but no IGW route, can't be reached from the internet.
- **AWS reserves 5 IP addresses in every subnet**: network address (`.0`), VPC router (`.1`), DNS (`.2`), future use (`.3`), and broadcast (`.255`, last). So a `/24` gives 251 usable, not 256. (Exam-frequent.)
- **VPC CIDR** must be `/16`–`/28`. CIDR blocks can't overlap if you plan to peer VPCs later.
- **Every new VPC gets 3 freebies**: a **main route table**, a **default NACL** (allow-all in/out), and a **default security group** (self-referencing inbound + allow-all outbound). Terraform ignores these unless you adopt them with the `aws_default_*` resources. **Best practice: never add an IGW route to the main route table** — so a subnet you forget to associate fails *closed* (private), not open.
- **IGW**: horizontally scaled, redundant, no bandwidth limit, one per VPC, free (you pay for the data transfer, not the IGW). Bidirectional.
- **NAT gateway**: managed, ~5 Gbps scaling automatically up to a higher ceiling (⚠️ verify current bandwidth ceiling), redundant **within one AZ** but **AZ-scoped** — for real HA you deploy **one NAT gateway per AZ** and point each private subnet's RT at the NAT in its own AZ (else an AZ failure cuts egress, and cross-AZ NAT traffic is billed). Has **no security group**. Needs an EIP. Bills **~$0.045/hr + per-GB data processed** — ⚠️ check current pricing. Outbound-only; drops unsolicited inbound.
- **Egress-only Internet Gateway (`aws_egress_only_internet_gateway`)**: the **IPv6** equivalent of a NAT gateway — outbound-only internet for IPv6 (IPv6 is globally routable, so you can't use NAT; you use this instead). IPv4 has no analog need because private IPv4 isn't routable.

## Comparisons

### NAT Gateway vs NAT Instance

|   | NAT Gateway | NAT Instance (legacy) |
|---|---|---|
| Managed by | AWS | You (it's an EC2 instance) |
| HA | Redundant within an AZ; 1 per AZ for cross-AZ HA | Manual (script failover / ASG) |
| Bandwidth | Scales automatically | Bounded by instance type |
| Security group | **None** (can't attach) | Yes (it's an EC2 instance) |
| Source/dest check | N/A | **Must be disabled** |
| Bastion / port-forward | No | Yes (can double as bastion) |
| Maintenance/patching | AWS | You |
| Cost | Hourly + data processing | EC2 hourly (+ can be smaller/cheaper) |

Exam default: **NAT gateway** unless the question emphasizes cost-at-tiny-scale or needing the NAT box to also be a bastion → NAT instance.

### IGW vs NAT Gateway vs Egress-only IGW

|   | IGW | NAT Gateway | Egress-only IGW |
|---|---|---|---|
| Protocol | IPv4 + IPv6 | IPv4 | IPv6 |
| Direction | Bidirectional | Outbound only | Outbound only |
| Lives | VPC edge | In a public subnet | VPC edge |
| For | public subnets | private subnets (IPv4) | private IPv6 egress |

## Worked examples

> [!example] Worked example — the three-tier web app network
> A classic layout your [[04-alb-asg]] stack belongs in: **public subnets** (2 AZs) hold the internet-facing ALB and a bastion; **private "app" subnets** (2 AZs) hold the ASG instances (reachable only from the ALB's SG); **private "data" subnets** (2 AZs) hold RDS (reachable only from the app SG). Only the ALB has a public path in; instances pull updates *out* via a **per-AZ NAT gateway**; the database has no internet route at all. Every tier is one route-table decision. This is the canonical SAA-C03 diagram — memorize the shape.

> [!failure] Failure mode — NAT gateway in the wrong subnet (the routing loop)
> Placing the NAT gateway in a **private** subnet (or pointing the private RT's default route at a NAT that lives in that same private subnet) creates a loop: the NAT's own egress follows `0.0.0.0/0 → itself`, never reaching the IGW. AWS **creates it without error**, so there's no failure message — private instances just silently have no internet, and you burn an hour debugging "why can't my instance apt-install." Fix: the NAT gateway must sit in a **public** subnet (one whose RT routes to the IGW); the private RT points *at* the NAT, the NAT's own subnet points at the IGW. (Hit live while building this topic.)

> [!failure] Failure mode — single NAT gateway as an AZ SPOF
> Deploying one NAT gateway and routing *all* private subnets (across AZs) through it saves money but makes that AZ a single point of failure: if the NAT's AZ goes down, every private subnet in every AZ loses egress, and in normal operation cross-AZ traffic to the NAT is billed. Production fix: **one NAT gateway per AZ**, each AZ's private RT → its local NAT. Cost vs resilience tradeoff the exam probes.

## The Terraform I wrote

Code: [`05-vpc/network.tf`](../05-vpc/network.tf) (core) + [`05-vpc/nat.tf`](../05-vpc/nat.tf) (paid peek)

- `data.aws_availability_zones` → `.names[0]/[1]` for the AZs; `aws_vpc.this` with DNS attributes on; 4 subnets (2 public with `map_public_ip_on_launch = true`, 2 private without); `aws_internet_gateway`; `aws_route_table.public` (inline `route` → IGW) + `aws_route_table.private` (no internet route); 4 `aws_route_table_association`.
- NAT peek: `aws_eip.nat` + `aws_nat_gateway.this` (in **public-a**, `depends_on` the IGW) + `aws_route.private_nat` (`0.0.0.0/0 → nat` on the private RT).
- Console showed a **3rd route table** — the auto-created **main route table** AWS makes with every VPC (plus the default NACL + default SG). None are Terraform-managed.

> [!warning] Trap — "the default NACL and a new NACL behave the same"
> Opposite. The **default** NACL allows all traffic both ways; a **custom** NACL you create **denies all** until you add numbered rules. Same flip exists for the default vs custom SG. Getting the direction of the default wrong is a classic distractor.

> [!warning] Trap — "add the IGW route to the main route table to make setup simpler"
> Never. That makes every unassociated subnet public by default — a subnet you forget to wire becomes internet-exposed. Keep custom route tables and explicit associations so forgotten subnets fail closed.

> [!example]- Recreate-from-memory drill
> Build a 2-AZ VPC (`10.0.0.0/16`): 2 public + 2 private subnets, an IGW, a public RT (`0.0.0.0/0 → IGW`) associated to the public subnets, a private RT associated to the private subnets, then a NAT gateway (public subnet + EIP) with the private RT routing `0.0.0.0/0 → NAT`. Confirm in the console: public subnets auto-assign public IPs; the route-table Subnet-associations tabs match; NAT sits in a public subnet.
> > [!success]- Reference solution
> > See `05-vpc/network.tf` + `nat.tf`. The one people get wrong is the NAT gateway's `subnet_id` — it must be a **public** subnet.

## 🔴 My weak spots (this topic)   #weak-spot

- [ ] **NAT gateway subnet placement** — put it in a *private* subnet on the first try; it must be **public** (that's its own door to the IGW). The private RT points *at* it.
- [ ] **Default vs custom NACL/SG behavior flips** — default NACL allows all, custom NACL denies all; default SG self-references, new SG denies inbound. Easy to state backwards.
- [ ] **The 3 auto-created VPC defaults** (main RT, default NACL, default SG) — didn't expect the 3rd route table in the console; they're AWS freebies, not Terraform-managed.
- [ ] **Single-NAT AZ SPOF** — one NAT for all AZs is a resilience + cross-AZ-cost trap; production uses one per AZ.

## 🔗 Docs

- [VPC subnets & routing](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html)
- [Subnet reserved IPs (5 per subnet)](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html)
- [NAT gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) — per-AZ HA, no SG, needs public subnet + EIP
- [NAT gateway vs NAT instance comparison](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-comparison.html)
- [Egress-only internet gateways (IPv6)](https://docs.aws.amazon.com/vpc/latest/userguide/egress-only-internet-gateway.html)
- [Terraform `aws_vpc`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) / [`aws_nat_gateway`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)

---
**Cards for this topic:** [[cards/05-vpc-core-cards]]
