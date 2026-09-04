###############################################################################
# Health check — deliberately BASIC, and therefore free.
#
# HTTP (not HTTPS), 30s interval (not the 10s "fast" option), no string
# matching, no latency graphs. Every one of those is an "optional feature" at
# $1.00/month EACH even on an AWS endpoint. This one counts against the 50
# free AWS-endpoint health checks, so it costs nothing.
#
# Time to go unhealthy ~= request_interval x failure_threshold = 30 x 3 = 90s,
# plus aggregation across health checkers. Budget ~2 minutes.
###############################################################################

resource "aws_route53_health_check" "primary" {
  fqdn              = aws_s3_bucket_website_configuration.primary.website_endpoint
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3

  tags = { Name = "${var.name_prefix}-primary-website" }
}
