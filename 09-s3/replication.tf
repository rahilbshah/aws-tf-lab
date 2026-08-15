# 09.2 Advanced — CROSS-REGION REPLICATION (CRR)
#
# Three things are required or replication silently does nothing:
#   a) versioning on BOTH buckets
#   b) an IAM role S3 assumes to read the source / write the destination
#   c) a replication configuration on the SOURCE bucket
#
# Cost: pennies (storage + a little cross-region transfer). Destroy after.

# ---------------------------------------------------------------------------
# 1. Destination bucket — note `provider = aws.dest` puts it in us-west-2.
#    Everything else in this project stays in us-east-1.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "dest" {
  provider = aws.dest
  bucket   = "saa-c03-dest-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "replication-destination"
  }
}

# Versioning on the DESTINATION is mandatory. Replication is built on versions:
# S3 replicates a specific object VERSION, so a non-versioned destination has
# nowhere to put it. (Source versioning already exists in main.tf.)
resource "aws_s3_bucket_versioning" "dest" {
  provider = aws.dest
  bucket   = aws_s3_bucket.dest.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------------------------------
# 2. The IAM service role S3 assumes to do the copying.
#    Exactly the trust-policy vs permissions-policy split from 01-iam:
#      - trust policy  = WHO can assume it   (the S3 service)
#      - permissions   = WHAT it may do      (read source, write destination)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  name               = "s3-replication-role"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
}

# Three statements, because replication needs three different kinds of access.
# Note the ARN shapes: bucket-level actions target the BUCKET arn, object-level
# actions target "<bucket arn>/*". Getting that wrong is the usual silent bug.
data "aws_iam_policy_document" "replication_permissions" {
  # (a) read the source bucket's replication config + list its contents
  statement {
    effect    = "Allow"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]
  }

  # (b) read the actual object VERSIONS (plus their ACLs/tags) from the source
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }

  # (c) write them into the destination
  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${aws_s3_bucket.dest.arn}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  name   = "s3-replication-policy"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication_permissions.json
}

# ---------------------------------------------------------------------------
# 3. The replication rule itself — lives on the SOURCE bucket.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "this" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.this.id # the SOURCE

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {} # empty = every object; could filter by prefix or tag instead

    # Delete markers are NOT replicated unless you opt in. Leaving this
    # Disabled means deleting in the source does NOT hide the object in the
    # destination — which is often what you want for a backup copy.
    delete_marker_replication {
      status = "Disabled"
    }

    destination {
      bucket = aws_s3_bucket.dest.arn

      # Replicas can land in a CHEAPER class than the source — a common
      # cost pattern: hot data in Standard, the DR copy in Standard-IA.
      storage_class = "STANDARD_IA"
    }
  }

  # S3 rejects a replication config if source versioning isn't active yet.
  depends_on = [aws_s3_bucket_versioning.this]
}
