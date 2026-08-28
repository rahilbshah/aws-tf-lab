###############################################################################
# 01-iam-lab — instance profile + IAM policy conditions
#
# An EC2 role that can read exactly ONE prefix of ONE bucket, and is
# structurally incapable of doing it over plain HTTP.
#
# Own root module, own state -> applying here touches nothing in 01-iam.
###############################################################################

data "aws_caller_identity" "current" {}

# --- Something to practise against -------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket        = "${var.name_prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "IAM lab prefix-scoped read target"
  }
}

resource "aws_s3_object" "ok" {
  bucket = aws_s3_bucket.this.id
  key    = "${var.allowed_prefix}ok.txt"
  source = "${path.module}/data.txt"
  etag   = filemd5("${path.module}/data.txt")
}

resource "aws_s3_object" "no" {
  bucket = aws_s3_bucket.this.id
  key    = "secret/no.txt"
  source = "${path.module}/data.txt"
  etag   = filemd5("${path.module}/data.txt")
}

# --- Trust policy: who may BECOME this role ----------------------------------

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "s3_reader" {
  name               = "${var.name_prefix}-s3-reader"
  description        = "Read-only access to the ${var.allowed_prefix} prefix of the lab bucket, TLS required."
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# --- The delivery mechanism: EC2 cannot hold a role directly -----------------

resource "aws_iam_instance_profile" "s3_reader" {
  name = "${var.name_prefix}-s3-reader"
  role = aws_iam_role.s3_reader.name
}

# --- Permissions policy: three statements, three different shapes ------------

data "aws_iam_policy_document" "permissions" {
  statement {
    sid     = "AllowGetObjectOnAllowedPrefix"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.this.arn}/${var.allowed_prefix}*"
    ]
  }

  statement {
    sid       = "AllowListBucketOnAllowedPrefixOnly"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.allowed_prefix}*"]
    }
  }

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "reports_read" {
  name        = "${var.name_prefix}-reports-read"
  description = "Allow GetObject + prefix-scoped ListBucket on the lab bucket; deny everything over plain HTTP."
  policy      = data.aws_iam_policy_document.permissions.json
}

resource "aws_iam_role_policy_attachment" "reports_read" {
  role       = aws_iam_role.s3_reader.name
  policy_arn = aws_iam_policy.reports_read.arn
}
