###############################################################################
# Origin Access Control + the distribution
###############################################################################

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.name_prefix}-oac"
  description                       = "Signs CloudFront's requests to the private S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # always sign -> CloudFront->S3 is always HTTPS
  signing_protocol                  = "sigv4"
}

# --- cache policies -----------------------------------------------------------
# Two tiers, which is the whole production caching pattern:
#   HTML  -> short TTL, because it is the only thing that must change fast
#   /static/* -> long TTL, safe because the filenames are fingerprinted

resource "aws_cloudfront_cache_policy" "html" {
  name        = "${var.name_prefix}-html-short-ttl"
  comment     = "Short TTL for the HTML entry point"
  min_ttl     = 0
  default_ttl = var.html_ttl
  max_ttl     = 300

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
    cookies_config { cookie_behavior = "none" }
    headers_config { header_behavior = "none" }
    query_strings_config { query_string_behavior = "none" }
  }
}

# AWS-managed policy: long TTL, strips cookies/headers/query strings from the
# cache key so the hit ratio is as high as possible.
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

# --- the distribution ---------------------------------------------------------

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = "SAA-C03 lab — private S3 origin via OAC"
  default_root_object = "index.html"

  # PriceClass_100 = US, Canada, Europe, Israel only — the cheapest tier.
  # Consequence you can actually observe: from India you'll be served by a
  # distant edge. Check the X-Amz-Cf-Pop header, then try PriceClass_All.
  price_class = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.origin.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.html.id
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      # To block or allow countries instead:
      #   restriction_type = "blacklist"   (or "whitelist")
      #   locations        = ["CN", "RU"]
    }
  }

  # The free *.cloudfront.net certificate. A custom domain would need an ACM
  # cert issued in us-east-1 — CloudFront only reads certificates from there,
  # regardless of where your origin lives.
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

###############################################################################
# The bucket policy — the confused-deputy defence, third costume
#
# `cloudfront.amazonaws.com` is the SAME principal for every AWS customer.
# Without the SourceArn condition, ANY CloudFront distribution in ANY account
# could read this bucket. The condition pins it to THIS distribution.
#
# (IAM condition key names are case-insensitive; AWS's CloudFront docs write
#  it as AWS:SourceArn, your 09-s3 code writes aws:SourceArn. Same key.)
###############################################################################

data "aws_iam_policy_document" "origin" {
  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.origin.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "origin" {
  bucket = aws_s3_bucket.origin.id
  policy = data.aws_iam_policy_document.origin.json

  # BPA blocks new public policies; ours isn't public, but ordering matters.
  depends_on = [aws_s3_bucket_public_access_block.origin]
}
