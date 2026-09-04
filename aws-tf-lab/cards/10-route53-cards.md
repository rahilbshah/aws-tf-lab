---
topic: 10-route53
domain: resilient
related_note: 10-route53
tags: [flashcards/route53]
---

# Cards for [[10-route53]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

What does registering a domain actually buy you, in DNS terms?
?
One thing: an NS record in the PARENT zone (e.g. in `.com`) pointing at your nameservers. That's the signpost letting strangers DISCOVER which server to ask. Route 53 will answer authoritatively for any zone it holds regardless — it never checks ownership. That's why you can build a full Route 53 lab on a domain you don't own and query the assigned nameservers directly with `dig @ns-…`.

Name all eight Route 53 routing policies.
?
Simple, Weighted, Latency, Failover, Geolocation, Geoproximity, Multivalue answer, IP-based.

With simple routing and three IP addresses in one record, what does Route 53 return?
?
ALL THREE, in random order, to the resolver — and the CLIENT picks one. It is NOT load balancing, and crucially the values are NOT health checked, so a dead server keeps being handed out. If you need distribution with health awareness, that's multivalue answer.

Simple routing vs multivalue answer — what is the actual difference?
?
Health checking. Both return several values at random. Multivalue answer returns up to EIGHT HEALTHY records and drops unhealthy ones; simple routing returns everything and checks nothing. That single difference is the exam question.

Geolocation vs geoproximity?
?
Geolocation routes on where the USER is — continent, country, or US state. Geoproximity routes on where your RESOURCES are, plus a BIAS value you set to expand or shrink each resource's catchment area, and it requires Route 53 Traffic Flow. "Users in Germany get the German site" = geolocation. "Shift more traffic to the bigger data centre" = geoproximity.

What happens to a geolocation query from a location none of your records match?
?
No answer at all — unless you created a record with country "*" as the default. Missing that default is a real outage: users outside your listed countries get nothing, not a fallback. Always create the "*" record.

When can you NOT use a CNAME, and why?
?
At the zone apex (example.com itself). The apex must carry SOA and NS records, and DNS forbids a CNAME coexisting with any other record at the same name. It's a protocol rule, not an AWS limitation. Also: any name with a CNAME can have no other records at all.

Name five things that make an Alias record different from a CNAME.
?
(1) Alias works at the zone apex, CNAME never does. (2) Alias points only at AWS resources (or another record in the same zone); CNAME points at any DNS name. (3) Alias queries to AWS resources are FREE; CNAME queries are charged. (4) You can't set a TTL on an alias to an AWS resource — it uses the target's. (5) Alias shows up as an A/AAAA record in dig; it's a Route 53 extension, not standard DNS.

Can an EC2 instance be an Alias target?
?
No. Valid alias targets are ALB/NLB/CLB, CloudFront, S3 static website endpoints, API Gateway, VPC interface endpoints, Global Accelerator, Elastic Beanstalk, App Runner, OpenSearch, AppSync, and another record in the same hosted zone. For EC2 you use a plain A record pointing at its Elastic IP.

How long does DNS failover actually take?
?
(health check interval x failure threshold) + TTL. With a 30-second interval and a threshold of 3, that's ~90 seconds before Route 53 even changes its answer, then up to a full TTL before clients stop using the cached one. The TTL term usually dominates — which is why failover-critical records use a TTL around 60 seconds, not 3600.

Failover is configured correctly and the console shows the health check failed, but users are still broken 40 minutes later. Why?
?
TTL. Resolvers and browsers cached the old answer and will keep serving it until it expires. Route 53 already switched. Fix: lower the TTL on the failover records (~60s). Note you cannot set a TTL at all on an alias to an AWS resource — Route 53 uses the target's, which is already low.

What are the three types of Route 53 health check?
?
(1) Endpoint — Route 53 fetches an IP or domain name directly. (2) Calculated — a parent health check watching up to 255 children, combined with AND / OR / "at least N healthy". (3) CloudWatch alarm — watches the alarm's DATA STREAM (not its state, so SetAlarmState can't fake it); same account only, no metric math, no M-of-N alarms.

What are the health check interval options and what does the failure threshold do?
?
30 seconds (standard) or 10 seconds ("fast", which costs extra as an optional feature). The failure threshold is the number of CONSECUTIVE checks that must fail — or pass — before Route 53 flips the status. Route 53 aggregates checkers worldwide: more than 18% reporting healthy means healthy.

Do HTTPS health checks validate the certificate?
?
No. AWS states explicitly that HTTPS health checks do not validate SSL/TLS certificates — an expired or invalid certificate still passes. For certificate expiry you need ACM plus CloudWatch/EventBridge, not a health check.

Why can't you health-check an instance in a private subnet?
?
Route 53's health checkers live on the public internet and cannot reach private, nonroutable, or multicast IP ranges. Check the public-facing load balancer instead, or use a CloudWatch alarm health check driven by a metric the private resource publishes.

What is required for a private hosted zone to work, and what happens if you query it from outside?
?
It must be associated with one or more VPCs, and those VPCs need DNS support and DNS hostnames enabled. Queried from outside an associated VPC, the name does NOT error — it just falls through to normal public recursive resolution. Private zones also get four reserved nameservers that are never actually contacted; they exist only because DNS requires an NS record set.

What is split-view (split-horizon) DNS on Route 53?
?
The same domain name existing in BOTH a public and a private hosted zone. Inside the associated VPC you get the private answer; from the internet you get the public one. Common for serving internal addresses to internal clients while the same name resolves publicly for everyone else.

Route 53 Resolver: what do inbound and outbound endpoints do?
?
INBOUND = queries coming INTO AWS — your on-premises resolver asking about AWS names (private hosted zones, VPC names). OUTBOUND = queries leaving AWS — your VPC resources asking about on-premises names, forwarded by resolver rules. Anchor on the direction the QUERY travels. (AWS has renamed this Route 53 VPC Resolver; exam material still says Route 53 Resolver.)

What IP address is the built-in VPC DNS resolver at?
?
The VPC's base address plus two — e.g. 10.0.0.2 in a 10.0.0.0/16 VPC. It answers for EC2 internal names, private hosted zones, and does recursive lookups for public names.

What is set_identifier in Terraform's aws_route53_record and when is it required?
?
A label distinguishing records that share the same name AND type. It's required for every routing policy where several records compete for one name — weighted, failover, latency, geolocation, geoproximity, multivalue. Plain DNS never needs it; it exists because Route 53 lets several records answer for one name.

How much does a hosted zone cost, and what's the exception?
?
$0.50/month for the first 25 zones, $0.10/month beyond. Exception: a hosted zone DELETED WITHIN 12 HOURS of creation is not charged — though queries against a public zone are still billed even in that window. That waiver is what makes short-lived DNS labs free.

How many health checks are free, and what makes one cost extra?
?
50 free for AWS endpoints (a resource in AWS in the same account); after that $0.50/month for AWS endpoints, $0.75 for non-AWS. Each OPTIONAL FEATURE costs $1.00/month on AWS endpoints ($2.00 non-AWS): HTTPS, string matching, the fast 10-second interval, and latency measurement. Keep lab checks basic and they stay free.

Which record type do you use for SPF data, and why not the SPF record type?
?
Use a TXT record. The SPF record type is deprecated — RFC 7208 says its use "is no longer appropriate for SPF version 1." Route 53 still supports the SPF type but AWS recommends against it.

In an MX record, does a higher or lower priority number win?
?
Lower wins. "10 mail1.example.com" is preferred over "20 mail2.example.com". Equal values split mail roughly evenly. The target must be an A/AAAA name, never a CNAME (RFC 2181 forbids it).

Which routing policy would you use for blue/green traffic shifting, and what's the gotcha?
?
Weighted, with two records sharing a name and different set_identifiers. Gotchas: the TTL bounds how fast a weight change takes effect (use ~60s), and a weight of 0 means "never return this record" — which is how you cleanly drain a stack. Attach health checks to both so a broken deployment is removed rather than served.
