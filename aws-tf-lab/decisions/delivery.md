---
decision: delivery
question: How should users reach this, globally?
spans: [10-route53, 11-cloudfront]
tags: [decision, domain/performance]
---

# How should users reach this, globally?

One front door, one name pointing at it, one place where failover lives. Work
top-down — the first question that applies settles it.

## 1. What protocol is the traffic?

The deciding question is **is it HTTP?** Not "is it slow", not "is it global" — all
three ride the same AWS edge network, so *speed* never separates them.

- **HTTP/HTTPS** → **CloudFront**. Cacheable content is the obvious case; uncacheable HTTP still wins, because the request joins the AWS backbone at the edge.
- **Not HTTP** — TCP/UDP, gaming, VoIP, IoT/MQTT — or **static IPs are a stated requirement** → **Global Accelerator**. It caches nothing.
- **Large uploads into one bucket from far away** → **S3 Transfer Acceleration**. Direction is the tell: that is upload, CloudFront is download.

↳ [[11-cloudfront#CloudFront vs S3 Transfer Acceleration vs Global Accelerator]]

## 2. What name points at it?

Ask **is the record at the zone apex?**

- **Apex** (`example.com`) → **alias**, no alternative. A CNAME there is invalid DNS, not an AWS limitation.
- **Subdomain, AWS target** → still **alias**: free queries, no TTL to set wrong, follows the target's IP changes.
- **Target outside AWS** → **CNAME**. **An EC2 instance** → neither; it is not a valid alias target, so use an **A record to an Elastic IP**.

↳ [[10-route53#Why a CNAME cannot sit at the apex]] · [[10-route53#Alias vs CNAME]]

## 3. What is allowed to vary the answer?

Match the sentence in the requirement, not the service:

- "just these addresses" → **simple** — nothing health checked, the client picks.
- "only the ones that are alive" → **multivalue answer**.
- "10% to the new stack", "drain this one" → **weighted**.
- "nearest Region" → **latency**; "nearest *of mine*, and let me tip it" → **geoproximity**.
- "users in Germany get the German site" → **geolocation** (reads the **user**).
- "primary, else the standby" → **failover**, then §4. "these CIDR blocks" → **IP-based**.

If it wants requests spread across healthy targets in one Region, none of these is it —
that is an **ALB**, and DNS is the wrong layer.

↳ [[10-route53#The eight routing policies]] · [[10-route53#The two policy pairs everyone swaps]]

## 4. Where does failover live?

The axis is **what has to change before traffic moves.**

- **The DNS answer** → **Route 53 failover**, bounded by `(interval × threshold) + TTL`, and the TTL term usually dominates.
- **Which origin one distribution uses** → **CloudFront origin group**: per request, no DNS involved.
- **Nothing — the address is identical either side** → **Global Accelerator**: seconds, because no resolver cached anything to wait out.

A private-subnet endpoint is invisible to Route 53 — health check the public-facing
load balancer, or use a **CloudWatch alarm** check.

↳ [[11-cloudfront#Why Global Accelerator fails over faster than DNS can]] · [[10-route53#What a health check can see, and how fast failover really is]]

## 5. Who is allowed through?

The axis is **whether, or where.**

- "Country X may not have this at all" → **CloudFront geo restriction** (edge, free); "Country X goes somewhere specific" → **Route 53 geolocation**.
- "This one file" → **signed URL**; "a whole section, or I can't change my URLs" → **signed cookies**.
- "Unreachable except through CloudFront" → **OAC**, and the bucket policy needs the `AWS:SourceArn` condition to mean anything.

↳ [[11-cloudfront#Signed URLs vs signed cookies (private content)]] · [[11-cloudfront#Why the S3 bucket policy needs a condition to actually be safe]]

## 6. Is the name meant for the internet at all?

The axis is **who is asking.**

- Only resources inside your VPCs → **private hosted zone**; both zones, same name → **split-view DNS**.
- **On-prem asking about AWS names** → Resolver **inbound**; **your VPC asking about on-prem names** → **outbound**. Anchor on where the *query* travels.

↳ [[10-route53#Public vs private hosted zone]] · [[10-route53#Route 53 Resolver — get the direction right]]

## 7. Must code run per request at the edge?

**Does it need the network, the request body, or an origin event?** No → **CloudFront Functions**. Yes to any → **Lambda@Edge**.

↳ [[11-cloudfront#CloudFront Functions vs Lambda@Edge]]

## The forks people take wrongly

These live *between* services, which is why they aren't in any single note.

- **Choosing CloudFront because the requirement says "global".** Both edge services are.
  The fork is protocol and cache — "static IPs" or non-HTTP settles it however much
  latency wording surrounds it.
- **Putting failover in DNS when the requirement is seconds.** Route 53 reacts in ~90s
  and then waits out every resolver's TTL. A stated RTO in seconds means anycast IPs
  that never change, not a lower TTL.
- **Using geolocation routing to block a country.** Routing decides *where to send*; it
  cannot deny. Licensing blocks are CloudFront geo restriction.
- **Picking the certificate's Region from where the app lives.** A viewer-facing
  CloudFront certificate is `us-east-1` whatever the origin does — and the wrong Region
  doesn't error, it silently never appears, so you go debugging ACM.
- **Deciding "S3 website endpoint" and "private bucket" separately.** One decision: a
  website endpoint is a custom origin, so it cannot use OAC. Wanting index documents on
  subfolders *is* choosing a public bucket.
- **Reaching for an alias because the target is on AWS.** The target list is fixed and
  EC2 is not on it. Apex plus a single instance means an Elastic IP and an A record.
- **Testing a routing policy only from where you are.** Geolocation with no `*` default
  answers three countries and goes silent for the rest, and one location exercises
  exactly one branch of whatever you chose.
