# Static website hosting (Section 1) — S3 can serve a plain HTML site directly.
#
# NOTE: a public website bucket requires turning OFF Block Public Access + a
# public-read bucket policy. That is DELIBERATE here (it's a website) but is
# exactly what you must NEVER do for a normal data bucket. We'll cover Block
# Public Access properly in the Security section (09-s3-security).
#
# Build:
#   - aws_s3_bucket.site                       a SECOND bucket, "saa-c03-site-<suffix>"
#
#   - aws_s3_bucket_website_configuration.site
#        bucket = aws_s3_bucket.site.id
#        index_document { suffix = "index.html" }
#        error_document { key    = "error.html" }
#
#   - aws_s3_bucket_public_access_block.site   ALL FOUR flags = false
#        (block_public_acls, block_public_policy, ignore_public_acls,
#         restrict_public_buckets) — otherwise the public policy is ignored
#
#   - aws_s3_bucket_policy.site                allow s3:GetObject to Principal "*"
#        on "${aws_s3_bucket.site.arn}/*"   (build with data.aws_iam_policy_document)
#        Use depends_on = [aws_s3_bucket_public_access_block.site] so the block is
#        lifted BEFORE the policy is applied (else AWS rejects the public policy).
#
#   - aws_s3_object.index / error             key = "index.html" / "error.html",
#        content = "<h1>...</h1>", content_type = "text/html"   <-- content_type matters,
#        without it browsers download instead of rendering
#
#   - output the website endpoint:
#        aws_s3_bucket_website_configuration.site.website_endpoint
#
# Then open the endpoint in a browser — a real static site, no servers.
# (Note: the S3 website endpoint is HTTP-only; HTTPS needs CloudFront in front.)


resource "aws_s3_bucket" "site" {
  bucket = "saa-c03-site-${data.aws_caller_identity.current.account_id}"
  tags = {
    Name = "My site"
  }
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "site" {
  bucket     = aws_s3_bucket.site.id
  policy     = data.aws_iam_policy_document.site.json
  depends_on = [aws_s3_bucket_public_access_block.site]
}

data "aws_iam_policy_document" "site" {
  statement {
    sid    = "AllowReadForSpecificPrincipal"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  etag         = filemd5("${path.module}/index.html")
  content_type = "text/html" # ← without this, S3 sends binary/octet-stream
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = "error.html"
  source       = "${path.module}/error.html"
  etag         = filemd5("${path.module}/error.html")
  content_type = "text/html" # ← without this, S3 sends binary/octet-stream
}
