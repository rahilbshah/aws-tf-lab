# ==========================================================================
# PHASE 6 — HTTPS for the user without owning a domain, and an ALB that
# refuses everyone except CloudFront.
#
# COST: at lab traffic, effectively nothing. CloudFront takes 5-15 minutes to
# deploy and to update - plan for that.
# ==========================================================================

# TODO(43) aws_cloudfront_distribution.this
#          enabled = true
#          origin {
#            domain_name = aws_lb.this.dns_name
#            origin_id   = "alb"
#            custom_origin_config {
#              http_port = 80, https_port = 443,
#              origin_protocol_policy = "http-only"     (CloudFront -> ALB is HTTP, inside AWS)
#              origin_ssl_protocols   = ["TLSv1.2"]
#            }
#          }
#          default_cache_behavior {
#            target_origin_id = "alb", viewer_protocol_policy = "redirect-to-https",
#            allowed_methods = ["GET","HEAD","OPTIONS","PUT","POST","PATCH","DELETE"],
#            cached_methods  = ["GET","HEAD"],
#            cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
#            origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
#          }
#          restrictions { geo_restriction { restriction_type = "none" } }
#          viewer_certificate { cloudfront_default_certificate = true }    <- free HTTPS on *.cloudfront.net
#
#          Two data sources for the managed policies:
#            data "aws_cloudfront_cache_policy"          "caching_disabled" { name = "Managed-CachingDisabled" }
#            data "aws_cloudfront_origin_request_policy" "all_viewer"       { name = "Managed-AllViewer" }
#          CachingDisabled because this is a dynamic API - you want every /db
#          call to reach the origin. AllViewer forwards headers/cookies/query
#          strings through. (Caching a static site would use CachingOptimized.)

# ---- lock the ALB to CloudFront ----------------------------------------------
# TODO(44) data.aws_ec2_managed_prefix_list.cloudfront
#            name = "com.amazonaws.global.cloudfront.origin-facing"
#          (verified to exist in this account as pl-3b927c52)
#
# TODO(45) Change the ALB's port-80 ingress rule from cidr_ipv4 = "0.0.0.0/0" to
#            prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
#
#          This is the origin-side half of the same lesson as OAC in 11-cloudfront:
#          without it, anyone who finds the ALB's DNS name bypasses CloudFront
#          entirely. With it, the ALB accepts packets only from CloudFront's
#          published IP ranges, and AWS keeps that list current for you.
#
# PHASE 6 IS DONE when:  curl https://<dist>.cloudfront.net/     -> works, over TLS
#                        curl http://<alb-dns>/                  -> HANGS / times out
# That timeout is the success condition. Say why before you test it.
