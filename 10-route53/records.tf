###############################################################################
# The routing policies. All addresses are RFC 5737 documentation ranges
# (192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24) — reserved for examples and
# guaranteed never to route anywhere, same spirit as the .example TLD.
#
# We are testing what DNS ANSWERS, not what the addresses serve.
###############################################################################

# --- 1. SIMPLE: one record, three values ------------------------------------
# No load balancing and NO health checking. Route 53 returns all three values
# in random order and the CLIENT picks one.

resource "aws_route53_record" "simple" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "simple.${var.zone_name}"
  type    = "A"
  ttl     = var.record_ttl
  records = ["192.0.2.1", "192.0.2.2", "192.0.2.3"]
}

# --- 2. WEIGHTED: 90 / 10 ----------------------------------------------------
# Separate records sharing a name, distinguished by set_identifier. That
# argument exists ONLY because multiple records can share a name+type here.

resource "aws_route53_record" "weighted_blue" {
  zone_id        = aws_route53_zone.this.zone_id
  name           = "weighted.${var.zone_name}"
  type           = "A"
  ttl            = var.record_ttl
  records        = ["198.51.100.10"]
  set_identifier = "blue"

  weighted_routing_policy { weight = 90 }
}

resource "aws_route53_record" "weighted_green" {
  zone_id        = aws_route53_zone.this.zone_id
  name           = "weighted.${var.zone_name}"
  type           = "A"
  ttl            = var.record_ttl
  records        = ["198.51.100.20"]
  set_identifier = "green"

  weighted_routing_policy { weight = 10 }
}

# --- 3. FAILOVER: primary + secondary, driven by the health check -----------
# CNAMEs to the real S3 website endpoints. Legal here because this is
# `www.<zone>`, not the zone apex — a CNAME at the apex would be invalid DNS.

resource "aws_route53_record" "www_primary" {
  zone_id         = aws_route53_zone.this.zone_id
  name            = "www.${var.zone_name}"
  type            = "CNAME"
  ttl             = var.record_ttl
  records         = [aws_s3_bucket_website_configuration.primary.website_endpoint]
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id

  failover_routing_policy { type = "PRIMARY" }
}

resource "aws_route53_record" "www_secondary" {
  zone_id        = aws_route53_zone.this.zone_id
  name           = "www.${var.zone_name}"
  type           = "CNAME"
  ttl            = var.record_ttl
  records        = [aws_s3_bucket_website_configuration.secondary.website_endpoint]
  set_identifier = "secondary"

  failover_routing_policy { type = "SECONDARY" }
}

# --- 4. MULTIVALUE ANSWER: the health-checked contrast to simple ------------
# Up to eight HEALTHY records returned at random. Compare with `simple` above:
# same shape of answer, but unhealthy records are removed. One of these is
# wired to the same health check, so it disappears when we break the bucket.

resource "aws_route53_record" "mv_one" {
  zone_id         = aws_route53_zone.this.zone_id
  name            = "multivalue.${var.zone_name}"
  type            = "A"
  ttl             = var.record_ttl
  records         = ["203.0.113.1"]
  set_identifier  = "one"
  health_check_id = aws_route53_health_check.primary.id

  multivalue_answer_routing_policy = true
}

resource "aws_route53_record" "mv_two" {
  zone_id                          = aws_route53_zone.this.zone_id
  name                             = "multivalue.${var.zone_name}"
  type                             = "A"
  ttl                              = var.record_ttl
  records                          = ["203.0.113.2"]
  set_identifier                   = "two"
  multivalue_answer_routing_policy = true
}

resource "aws_route53_record" "mv_three" {
  zone_id                          = aws_route53_zone.this.zone_id
  name                             = "multivalue.${var.zone_name}"
  type                             = "A"
  ttl                              = var.record_ttl
  records                          = ["203.0.113.3"]
  set_identifier                   = "three"
  multivalue_answer_routing_policy = true
}

# --- 5. GEOLOCATION: by where the USER is -----------------------------------
# The "*" default is mandatory in practice: a query from an unmatched location
# gets NO ANSWER without it. That omission is a classic outage.

resource "aws_route53_record" "geo_default" {
  zone_id        = aws_route53_zone.this.zone_id
  name           = "geo.${var.zone_name}"
  type           = "A"
  ttl            = var.record_ttl
  records        = ["192.0.2.100"]
  set_identifier = "default"

  geolocation_routing_policy { country = "*" }
}

resource "aws_route53_record" "geo_us" {
  zone_id        = aws_route53_zone.this.zone_id
  name           = "geo.${var.zone_name}"
  type           = "A"
  ttl            = var.record_ttl
  records        = ["192.0.2.101"]
  set_identifier = "us"

  geolocation_routing_policy { country = "US" }
}

resource "aws_route53_record" "geo_in" {
  zone_id        = aws_route53_zone.this.zone_id
  name           = "geo.${var.zone_name}"
  type           = "A"
  ttl            = var.record_ttl
  records        = ["192.0.2.102"]
  set_identifier = "in"

  geolocation_routing_policy { country = "IN" }
}

# --- 6. LATENCY: by which REGION is fastest for the user --------------------
# Note what changes vs geolocation: you name an AWS REGION, not a country.
# Route 53 uses its own latency measurements, not the map.

resource "aws_route53_record" "latency_east" {
  zone_id        = aws_route53_zone.this.zone_id
  name           = "latency.${var.zone_name}"
  type           = "A"
  ttl            = var.record_ttl
  records        = ["198.51.100.1"]
  set_identifier = "us-east-1"

  latency_routing_policy { region = "us-east-1" }
}

resource "aws_route53_record" "latency_west" {
  zone_id        = aws_route53_zone.this.zone_id
  name           = "latency.${var.zone_name}"
  type           = "A"
  ttl            = var.record_ttl
  records        = ["198.51.100.2"]
  set_identifier = "us-west-2"

  latency_routing_policy { region = "us-west-2" }
}
