###############################################################################
# 10-route53 — DNS routing policies, health checks and failover
#
# No domain is purchased. Route 53 answers authoritatively for any zone it
# hosts, to anyone who asks it DIRECTLY — delegation from the parent zone is
# only how the internet DISCOVERS which nameserver to ask. We skip discovery
# and query the four assigned nameservers ourselves with `dig @<ns>`.
#
# See VERIFY.md for the observation protocol.
###############################################################################

data "aws_caller_identity" "current" {}

resource "aws_route53_zone" "this" {
  name    = var.zone_name
  comment = "SAA-C03 lab — not a real domain, never delegated. Delete within 12h to avoid the $0.50/mo charge."
}
