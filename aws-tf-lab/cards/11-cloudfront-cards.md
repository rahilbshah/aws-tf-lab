---
topic: 11-cloudfront
domain: performance
related_note: 11-cloudfront
tags: [flashcards/cloudfront]
---

# Cards for [[11-cloudfront]]
*Spaced-repetition cards. Review via the SR plugin command palette.*

Walk through what happens on a CloudFront cache miss.
?
The edge location doesn't have the object, so it checks the REGIONAL EDGE CACHE; if that misses too it fetches from the origin. The object is stored at the edge on the way back and served. Subsequent requests are hits until the TTL expires. Check the `X-Cache` response header: "Miss from cloudfront" vs "Hit from cloudfront".

Is CloudFront only useful for static content?
?
No. Dynamic, uncacheable requests still benefit, because they enter the AWS global backbone at the nearest edge rather than crossing the public internet end to end. Putting CloudFront in front of a dynamic API is a real optimisation, not just a static-asset trick.

How do you stop people bypassing CloudFront and hitting your S3 bucket directly?
?
Origin Access Control (OAC). Attach it to the S3 origin, then add a bucket policy allowing s3:GetObject to the service principal `cloudfront.amazonaws.com` with a Condition on `AWS:SourceArn` equal to your distribution's ARN. Block Public Access stays FULLY ON — the bucket is completely private and CloudFront is the only way in.

Why does the OAC bucket policy need a SourceArn condition when it already works without one?
?
Because `cloudfront.amazonaws.com` is the SAME service principal for every AWS customer. Without the condition, anyone who learns your bucket name can point THEIR OWN distribution at it and serve your content on their domain. The condition isn't what makes your distribution work — it's what stops everyone else's. The bug is completely invisible in testing.

OAC vs OAI — which is current, and what does the older one not support?
?
OAC is current and recommended; OAI is legacy. OAI does not support: all AWS Regions (including opt-in Regions launched after Dec 2022 / Jan 2023), SSE-KMS encrypted objects, or dynamic PUT/POST/DELETE requests. To migrate, allow both principals in the bucket policy, switch the distribution to OAC, then remove the OAI statement.

Can you use OAC with an S3 bucket configured as a website endpoint?
?
No. An S3 website endpoint is treated as a CUSTOM origin, and custom origins support neither OAC nor OAI. OAC requires the S3 REST endpoint (`bucket.s3.region.amazonaws.com`). Consequence: with the REST endpoint you lose S3's website features (subfolder index documents, S3 redirect rules) and use CloudFront's default_root_object and custom error pages instead.

What can be a CloudFront origin?
?
S3 (REST endpoint), an S3 website endpoint (as a custom origin), S3 Access Points / Object Lambda / Multi-Region Access Points, MediaStore and MediaPackage, ALB, NLB, EC2, Lambda function URLs, API Gateway, and any public HTTP(S) server including on-premises. VPC origins additionally allow an ALB, NLB or EC2 instance in a PRIVATE subnet with no public exposure.

What is a CloudFront origin group?
?
CloudFront's own origin failover: a primary and a secondary origin, where CloudFront switches to the secondary when the primary returns configured HTTP failure status codes. No DNS involved — distinct from Route 53 failover routing.

How much does invalidation cost, and what does AWS recommend instead?
?
The first 1,000 invalidation paths per month per AWS ACCOUNT (across all distributions) are free; a path containing `*` counts as ONE path however many files it clears. AWS recommends VERSIONED FILE NAMES instead — because invalidation can't reach a user's browser cache or a corporate proxy, and versioning gives clean rollbacks, clearer access logs, and the ability to serve different versions to different users.

Describe the two-tier caching pattern for a website.
?
Short TTL on the HTML entry point (it's tiny and it's the only thing that must change fast), and a very long TTL on fingerprinted assets like `app.a1b2c3.css` — because the hash is in the FILENAME, so a new build produces a new name and therefore a new cache key. Nothing ever needs invalidating, and users mid-session keep working off the old asset instead of getting a half-updated page.

Which Region must an ACM certificate be in to use with CloudFront?
?
us-east-1 (N. Virginia), for viewer-to-CloudFront HTTPS — regardless of where your origin, bucket or users are. A valid certificate in another Region simply won't appear in the distribution's certificate list. One exception: a certificate for CloudFront-to-ORIGIN HTTPS with an ELB origin can be in any Region.

What HTTP status do viewers get if the origin's certificate doesn't match the origin domain name?
?
502 Bad Gateway. One of the domain names in the origin's certificate (Common Name or Subject Alternative Names, wildcards allowed) must match the origin domain name you configured.

CloudFront Functions vs Lambda@Edge — the main differences?
?
Functions: JavaScript only, VIEWER request/response events only, sub-millisecond, 2 MB memory, 10 KB code, NO network access, NO request body, millions of req/sec. Lambda@Edge: Node.js/Python, all four events (viewer AND origin request/response), up to 30 seconds, 128 MB–10 GB, 50 MB code, network access yes, request body yes, 10,000 req/sec per Region.

Which one for: rewriting a URL at massive scale? Calling DynamoDB from the edge?
?
URL rewrite at scale → CloudFront Functions (sub-millisecond, cheap, designed for header/URL manipulation and cache-key normalisation). Calling DynamoDB → Lambda@Edge, because Functions have no network access and can't use the AWS SDK.

CloudFront vs Global Accelerator?
?
CloudFront caches HTTP content at edge locations. Global Accelerator caches NOTHING — it gives you two static anycast IPs (four for dual-stack) and routes any TCP/UDP traffic over the AWS backbone to the nearest healthy Region. Global Accelerator triggers: static IPs required, non-HTTP protocol, gaming/VoIP/IoT, or failover in seconds. Endpoints are NLB, ALB, EC2 or Elastic IPs.

Why does Global Accelerator fail over faster than Route 53?
?
Because its IP addresses never change, so there is nothing for a DNS resolver to cache. Route 53 failover is bounded by (health check interval x failure threshold) + TTL, and the TTL term usually dominates. Global Accelerator reacts to health changes instantly with no DNS involved at all.

CloudFront vs S3 Transfer Acceleration?
?
Both use CloudFront edge locations. Transfer Acceleration is S3-specific and aimed at UPLOADS: the client hits a nearby edge, then the data rides the AWS backbone to the bucket. It does not cache. CloudFront caches content for DOWNLOADS/delivery. "Users worldwide upload large files to one bucket" → Transfer Acceleration.

Signed URLs vs signed cookies?
?
Signed URL = access to ONE individual file; use it when the client can't handle cookies. Signed cookies = access to MULTIPLE files (a whole members' area, all HLS video segments) without changing your existing URLs. Both work with S3 and custom origins. Signers are configured as trusted key groups (recommended) or legacy trusted signers.

CloudFront signed URL vs S3 presigned URL?
?
An S3 presigned URL carries the permissions of whoever generated it and only works for S3. A CloudFront signed URL is a CloudFront-level control that also works for custom origins, and it can be combined with WAF, geo restriction and caching. If content is served through CloudFront, use CloudFront signed URLs.

CloudFront geo restriction vs Route 53 geolocation routing?
?
Geo restriction decides WHETHER a country may access the content at all — an allow/block list enforced at the edge, used for licensing and compliance. Route 53 geolocation routing decides WHICH endpoint a country is sent to. "Block viewers in country X" → CloudFront. "Send German users to the German site" → Route 53.

What are CloudFront price classes and what do they trade off?
?
PriceClass_100 (US, Canada, Europe, Israel), PriceClass_200 (adds most of Asia, Middle East, Africa), PriceClass_All (everywhere). Fewer edge locations costs less but leaves some users further from a cache. You can see which edge served you in the `X-Amz-Cf-Pop` response header.

Which CloudFront response headers tell you what the cache did?
?
`X-Cache` — "Hit from cloudfront" or "Miss from cloudfront". `Age` — how many seconds the object has been cached. `X-Amz-Cf-Pop` — which edge location served the request. `X-Amz-Cf-Id` — an identifier for correlating with logs and AWS Support.

Is data transfer from your S3 bucket to CloudFront charged?
?
No — data transfer from AWS origins to CloudFront is waived. You pay for CloudFront's data transfer out to viewers and for requests. This is part of why fronting S3 with CloudFront is often cheaper than serving from S3 directly at scale.
