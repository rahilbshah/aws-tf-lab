###############################################################################
# Two S3 static websites — the real, breakable endpoints behind the failover
# demo. Same pattern you already built in 09-s3/website.tf.
#
# These are deliberately PUBLIC: an S3 website endpoint cannot serve content
# otherwise. That is the intended configuration for static hosting, not an
# oversight — but it is exactly why Block Public Access exists and why you
# turn it off explicitly rather than by accident.
###############################################################################

locals {
  primary_bucket   = "${var.name_prefix}-primary-${data.aws_caller_identity.current.account_id}"
  secondary_bucket = "${var.name_prefix}-secondary-${data.aws_caller_identity.current.account_id}"
}

# ---------- primary (us-east-1) ----------

resource "aws_s3_bucket" "primary" {
  bucket        = local.primary_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "primary" {
  bucket                  = aws_s3_bucket.primary.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id
  index_document { suffix = "index.html" }
}

data "aws_iam_policy_document" "primary_public_read" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.primary.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "primary" {
  bucket     = aws_s3_bucket.primary.id
  policy     = data.aws_iam_policy_document.primary_public_read.json
  depends_on = [aws_s3_bucket_public_access_block.primary]
}

resource "aws_s3_object" "primary_index" {
  bucket       = aws_s3_bucket.primary.id
  key          = "index.html"
  content      = "<h1>PRIMARY — us-east-1</h1>\n"
  content_type = "text/html"
}

# ---------- secondary (us-west-2) ----------

resource "aws_s3_bucket" "secondary" {
  provider      = aws.secondary
  bucket        = local.secondary_bucket
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "secondary" {
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.secondary.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  index_document { suffix = "index.html" }
}

data "aws_iam_policy_document" "secondary_public_read" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.secondary.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "secondary" {
  provider   = aws.secondary
  bucket     = aws_s3_bucket.secondary.id
  policy     = data.aws_iam_policy_document.secondary_public_read.json
  depends_on = [aws_s3_bucket_public_access_block.secondary]
}

resource "aws_s3_object" "secondary_index" {
  provider     = aws.secondary
  bucket       = aws_s3_bucket.secondary.id
  key          = "index.html"
  content      = "<h1>SECONDARY — us-west-2</h1>\n"
  content_type = "text/html"
}
