# 09 – S3 Section 1 (Introduction): bucket, versioning, lifecycle, static site.
# Essentially FREE (storage is pennies; requests are free-tier).
#
# KEY TERRAFORM SHIFT vs older tutorials: modern AWS provider splits bucket
# settings into SEPARATE resources instead of inline blocks on aws_s3_bucket.
# You'll create one bucket + several sibling resources that each configure it.
#
# Build:
#   1. random_id / suffix for global uniqueness
#      Bucket names are GLOBALLY unique, so hardcoding "my-bucket" will fail.
#      Easiest: resource "random_id" "suffix" { byte_length = 4 }  -> use in the name
#      (add `random` to required_providers in versions.tf), OR use
#      data.aws_caller_identity.current.account_id as the suffix. Your call.
#
#   2. aws_s3_bucket.this            bucket = "saa-c03-lab-<suffix>", tags
#
#   3. aws_s3_bucket_versioning.this
#        bucket = aws_s3_bucket.this.id
#        versioning_configuration { status = "Enabled" }
#
#   4. aws_s3_bucket_lifecycle_configuration.this   – the cost lesson
#        bucket = aws_s3_bucket.this.id
#        rule {
#          id = "archive-then-expire"; status = "Enabled"
#          filter {}                                  # empty = whole bucket
#          transition { days = 30  storage_class = "STANDARD_IA" }
#          transition { days = 90  storage_class = "GLACIER" }
#          expiration { days = 365 }
#          noncurrent_version_expiration { noncurrent_days = 30 }   # clean old versions
#          abort_incomplete_multipart_upload { days_after_initiation = 7 }
#        }
#
#   5. Upload a test object so you can SEE versioning work:
#      aws_s3_object.hello  bucket, key = "hello.txt", content = "v1", content_type = "text/plain"
#      (change content to "v2" + re-apply later to create a second VERSION)
#
# Note the "key" is the full path-like object name (e.g. "docs/hello.txt") —
# S3 is a FLAT key->object map; "folders" are just a console display trick.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket        = "saa-c03-lab-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = {
    Name = "My bucket"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    id     = "archive-then-expire"
    status = "Enabled"
    filter {}
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_object" "hello" {
  bucket = aws_s3_bucket.this.id
  key    = "data.txt"
  source = "${path.module}/data.txt"
  etag   = filemd5("${path.module}/data.txt")
}
