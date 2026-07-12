---
topic: 05-vpc-core
domain: resilient
related_note: 05-vpc-core
tags: [flashcards/vpc]
---

# Cards for [[05-vpc-core]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What two conditions make a subnet "public"?
?
Both required: (1) the subnet's route table has a route `0.0.0.0/0 → Internet Gateway`, and (2) instances get a public IP (`map_public_ip_on_launch = true`, or an attached EIP). Miss either and the subnet is effectively private. There is no "public" checkbox — it's a consequence of routing + IP.

What decides whether a subnet is public or private?
?
Its route table. A subnet routed to an IGW (with public IPs) is public; one without an internet route is private. Any subnet NOT explicitly associated with a route table falls back to the VPC's main route table.

What direction does an Internet Gateway vs a NAT gateway allow, and where does each live?
?
IGW: bidirectional, sits at the VPC edge, one per VPC — for public subnets. NAT gateway: outbound-only (private instances reach the internet, but the internet can't initiate inbound), and it lives IN a public subnet (that's its own path to the IGW). The private route table points 0.0.0.0/0 at the NAT.

Why must a NAT gateway be placed in a PUBLIC subnet?
?
To do its job it must send translated outbound traffic to the internet, which requires a route to the IGW — and only a public subnet's route table has 0.0.0.0/0 → IGW. Put it in a private subnet and its own egress loops back to itself (or has no IGW path), so private instances silently get no internet. AWS creates it without error, so the failure is silent.

What 3 things does AWS auto-create with every new VPC?
?
A main route table, a default network ACL (allow-all inbound and outbound), and a default security group (self-referencing inbound allow + allow-all outbound). Terraform doesn't manage these unless you adopt them via aws_default_route_table / aws_default_network_acl / aws_default_security_group.

Default NACL vs a new custom NACL — how do their defaults differ?
?
Default NACL: allows ALL traffic in and out. A NEW custom NACL: DENIES all traffic in and out until you add numbered rules. They're opposites — a classic exam trap (mirror image of SGs: new SG denies inbound, default SG self-references).

How many IP addresses does AWS reserve in each subnet, and which?
?
5 per subnet: the network address (.0), the VPC router (.1), the DNS (.2), one reserved for future use (.3), and the broadcast address (last, e.g. .255). So a /24 has 251 usable addresses, not 256.

What's the scope of a VPC vs a subnet?
?
A VPC spans an entire region (all its AZs). A subnet lives in exactly ONE Availability Zone. To be multi-AZ you create one subnet per AZ — that's why HA designs use e.g. public-a/public-b + private-a/private-b.

NAT gateway vs NAT instance — name the key differences.
?
NAT gateway: AWS-managed, auto-scaling bandwidth, redundant within an AZ (1 per AZ for HA), NO security group, no maintenance. NAT instance: a legacy EC2 box you manage — must disable source/dest check, HAS a security group, bandwidth bounded by instance type, manual HA, but CAN double as a bastion / do port forwarding. Exam default = NAT gateway.

Why is a single NAT gateway serving all AZs a problem?
?
It's an AZ single point of failure — if that AZ fails, every private subnet across all AZs loses outbound internet — and cross-AZ traffic to the NAT is billed. Production fix: one NAT gateway per AZ, each AZ's private route table pointing to its local NAT.

What is an egress-only internet gateway and when do you use it?
?
The IPv6 equivalent of a NAT gateway: outbound-only internet access for IPv6. Because IPv6 addresses are globally routable you can't use NAT for them, so you use an egress-only IGW to let private IPv6 instances reach out while blocking unsolicited inbound. IPv4 uses a NAT gateway instead.

Why should you never add an IGW route to the VPC's main route table?
?
The main route table is the fallback for any subnet not explicitly associated with a custom route table. If it routes to the IGW, a subnet you forget to associate becomes public by default — an accidental internet exposure. Keep the main RT internet-less so forgotten subnets fail closed (private).

Which two `aws_vpc` arguments enable DNS, and why set them?
?
enable_dns_support (resolve AWS-provided DNS) and enable_dns_hostnames (give instances public DNS names). Set both true — needed for public DNS names now, and enable_dns_hostnames is REQUIRED for interface VPC endpoints (PrivateLink) later.
