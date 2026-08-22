# 09.3 Security — a SECURE-BY-DEFAULT bucket.
#
# This is the deliberate opposite of website.tf (which is public ON PURPOSE
# because it serves a website). Everything here is the pattern you want for
# every normal data bucket.

resource "aws_s3_bucket" "secure" {
  bucket        = "saa-c03-secure-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # lab only

  tags = {
    Name = "secure-bucket"
  }
}

# ---------------------------------------------------------------------------
# 1. BLOCK PUBLIC ACCESS — the account/bucket-level safety net.
#
# Why FOUR settings? Because there are two ways a bucket can become public
# (an ACL or a policy) and two things you might want to do about each
# (block NEW ones vs ignore/override EXISTING ones):
#
#   block_public_acls       -> reject new public ACLs
#   ignore_public_acls      -> ignore any public ACLs already there
#   block_public_policy     -> reject new public bucket policies
#   restrict_public_buckets -> neutralise an existing public policy
#
# All four true = "this bucket cannot be made public, even by mistake."
# This OVERRIDES any policy, so it's a guardrail rather than a permission:
# a developer can write a public policy and it simply won't take effect.
# It can also be set ACCOUNT-wide (aws_s3_account_public_access_block), which
# is the recommended default for a whole AWS account.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "secure" {
  bucket = aws_s3_bucket.secure.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# 2. TURN OFF ACLs ENTIRELY.
#
# ACLs are the legacy (pre-IAM) way to grant access per-object. AWS now
# recommends disabling them so ALL access is decided by policies, which are
# far easier to audit. "BucketOwnerEnforced" means: ACLs are ignored, and the
# bucket owner automatically owns every object (even ones uploaded by another
# account). Since 2023 this is the default for new buckets.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_ownership_controls" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ---------------------------------------------------------------------------
# 3. A CUSTOMER-MANAGED KMS KEY for SSE-KMS.
#
# SSE-S3  = AWS owns and manages the key. Free, invisible, no audit trail.
# SSE-KMS = YOUR key in KMS. You control the key policy, rotation, and every
#           use is logged in CloudTrail — which is why compliance work wants it.
#
# ⚠️ COST/BEHAVIOUR: a customer-managed key costs ~$1/month (prorated) and
# `terraform destroy` does NOT delete it immediately — KMS only SCHEDULES
# deletion, minimum 7 days (that's the point: it stops you destroying the key
# that decrypts your data). So this key lingers ~7 days after teardown.
# If you'd rather stay free, delete this key + alias and change the encryption
# block below to sse_algorithm = "AES256" (that's SSE-S3).
# ---------------------------------------------------------------------------
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 SSE-KMS demo"
  deletion_window_in_days = 7 # minimum allowed
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3" {
  name          = "alias/saa-c03-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# ---------------------------------------------------------------------------
# 4. DEFAULT ENCRYPTION.
#
# "Default" means S3 encrypts every object written, even if the client didn't
# ask. Since Jan 2023 all buckets have SSE-S3 on by default; this upgrades it
# to SSE-KMS with our own key.
#
# bucket_key_enabled = true is a COST optimisation: without it S3 calls KMS
# once per object; with it S3 uses a short-lived bucket-level data key and can
# cut KMS request costs by up to 99%.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "secure" {
  bucket = aws_s3_bucket.secure.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# ---------------------------------------------------------------------------
# 5. A BUCKET POLICY THAT DENIES.
#
# Everything so far grants nothing — access still comes from IAM. This policy
# adds two DENY guardrails. Remember from 01-iam: an explicit Deny always wins,
# so these hold even if someone's IAM policy is generous.
#
#   (a) Deny any request not using HTTPS  (aws:SecureTransport = false)
#   (b) Deny uploads that aren't SSE-KMS encrypted
#
# Note the two ARN shapes again: bucket-level vs "<bucket>/*" for objects.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "secure" {
  # (a) HTTPS only — protects data in transit
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.secure.arn,
      "${aws_s3_bucket.secure.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # (b) Refuse any PutObject that isn't encrypted with SSE-KMS
  statement {
    sid    = "DenyUnencryptedUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.secure.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}

resource "aws_s3_bucket_policy" "secure" {
  bucket = aws_s3_bucket.secure.id
  policy = data.aws_iam_policy_document.secure.json

  # Block Public Access must be in place before we attach a policy, so the
  # guardrail is never briefly absent.
  depends_on = [aws_s3_bucket_public_access_block.secure]
}

# Versioning: protects against accidental delete/overwrite (see 09-s3-intro).
resource "aws_s3_bucket_versioning" "secure" {
  bucket = aws_s3_bucket.secure.id

  versioning_configuration {
    status = "Enabled"
  }
}
