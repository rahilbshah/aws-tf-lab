###############################################################################
# 11-cloudfront — CDN in front of a PRIVATE S3 origin
#
# Contrast with 10-route53: there the buckets had to be public, because an S3
# *website* endpoint cannot serve otherwise — and a website endpoint is a
# "custom origin", which cannot use OAC at all.
#
# Here we use the S3 *REST* endpoint, so Block Public Access stays FULLY ON
# and CloudFront is the only way in.
###############################################################################

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "origin" {
  bucket        = "${var.name_prefix}-origin-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# Every setting ON. This is the payoff of OAC — the bucket is completely
# private and still serves content worldwide.
resource "aws_s3_bucket_public_access_block" "origin" {
  bucket                  = aws_s3_bucket.origin.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- content ------------------------------------------------------------------
# Two objects that demonstrate the two-tier caching pattern.

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.origin.id
  key          = "index.html"
  content_type = "text/html"
  content      = <<-HTML
    <!doctype html>
    <html><head><link rel="stylesheet" href="/static/app.a1b2c3.css"></head>
    <body><h1>CloudFront lab — version 1</h1>
    <p>Edit this object, then watch the TTL expire or force an invalidation.</p>
    </body></html>
  HTML
}

# Fingerprinted: the hash is IN THE FILENAME. A new build produces a new name,
# which is a new cache key — so this can be cached for a year and never needs
# invalidating. That is why AWS recommends versioning over invalidation.
resource "aws_s3_object" "asset" {
  bucket       = aws_s3_bucket.origin.id
  key          = "static/app.a1b2c3.css"
  content_type = "text/css"
  content      = "body{font-family:system-ui;margin:3rem;color:#123}\n"
}
