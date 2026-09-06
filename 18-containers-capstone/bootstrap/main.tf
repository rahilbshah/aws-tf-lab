# ==========================================================================
# 18-containers-capstone / bootstrap
#
# PURPOSE: create the S3 bucket that holds Terraform state for every other
# config in this project. Run once. Then essentially never again.
#
# WHY THIS EXISTS AT ALL. Right now every lab keeps terraform.tfstate on your
# laptop. That is fine for one person on one machine and fails the moment you
# want any of: a second machine, a teammate, CI, or a laptop that dies. Remote
# state fixes all four, and adds locking so two applies can't race.
#
# WHAT CHANGED SINCE THE TUTORIALS YOU HAVE READ. Almost every guide tells you
# to create a DynamoDB table for locking. Do not. The S3 backend now locks
# natively with a lockfile object, and the docs say plainly that
# "DynamoDB-based locking is deprecated and will be removed in a future minor
# version". You will write `use_lockfile = true` and create no DynamoDB table.
#
# COST, plainly: a few state files is kilobytes. S3 Standard is ~$0.023/GB-mo,
# so this is fractions of a cent per month. Effectively free, and it is the one
# thing in this project you should NOT destroy at the end of a session.
#
# BUILD ORDER: 1 -> 8 in order. The bucket must exist before anything can be
# configured on it.
# ==========================================================================

# TODO(1) data.aws_caller_identity.current
#         No arguments. You want `.account_id` to build a globally unique
#         bucket name. Remember from 09-s3: bucket names are global across ALL
#         AWS accounts, so "tfstate" was taken roughly a decade ago.

# TODO(2) aws_s3_bucket.state
#         bucket = "${var.state_bucket_prefix}-${account id from (1)}"
#
#         Add a lifecycle block:
#           lifecycle { prevent_destroy = true }
#
#         Read that carefully, because I got it wrong before checking: the docs
#         say prevent_destroy makes Terraform "reject plans that would destroy
#         the infrastructure object ... and return an error". That is the guard
#         you want. Terraform 1.16 also added `destroy = false`, which is NOT a
#         guard - it means "remove from state WITHOUT destroying the real
#         resource". Different tool, different job.
#
#         Also set:  force_destroy = true
#
#         Those two look contradictory and are not. They guard different things:
#           prevent_destroy -> stops the ACCIDENT (a destroy run in the wrong
#                              folder, or a -target typo). Terraform errors out.
#           force_destroy   -> enables the INTENT. A versioned bucket refuses to
#                              delete while it still holds objects, and yours
#                              will hold every state version you ever wrote.
#                              Without this, even a deliberate teardown fails
#                              with BucketNotEmpty.
#
#         So the deliberate teardown is a two-step you cannot do by accident:
#           1. delete the prevent_destroy line
#           2. terraform destroy
#
#         THE ORDERING RULE THAT MATTERS: destroy the infrastructure BEFORE the
#         state that tracks it. Kill this bucket while live/dev still has a VPC
#         and an RDS running and Terraform forgets it owns them - they keep
#         billing and you delete them by hand in the console, one by one.

# TODO(3) aws_s3_bucket_versioning.state
#         bucket = the bucket, versioning_configuration { status = "Enabled" }
#
#         The single most important resource in this folder. State is the map
#         between your config and real infrastructure. Corrupt it and Terraform
#         no longer knows what it owns. Versioning means every previous state
#         is recoverable. Turn this on BEFORE you migrate any state into it.

# TODO(4) aws_s3_bucket_server_side_encryption_configuration.state
#         rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
#
#         State files contain, in plaintext, whatever your resources exposed -
#         connection strings, generated keys, and historically DB passwords.
#         (This project avoids the last one entirely; see phase 4.)
#         DESIGN CHOICE: "AES256" (SSE-S3, free) or "aws:kms" with a CMK
#         (audit trail per decrypt, ~$1/month + per-request). Pick SSE-S3 here
#         and know why you'd pick KMS at work.

# TODO(5) aws_s3_bucket_public_access_block.state
#         All four settings true: block_public_acls, block_public_policy,
#         ignore_public_acls, restrict_public_buckets.
#         Recall from 09-s3-security: S3 applies the MOST RESTRICTIVE
#         combination across org / account / bucket, so setting all four here
#         can only ever help.

# TODO(6) aws_s3_bucket_lifecycle_configuration.state
#         One rule, status "Enabled", with a `filter {}` block (an empty filter
#         means "all objects" - the argument is required in the v6 provider):
#           noncurrent_version_expiration {
#             noncurrent_days = var.noncurrent_version_expiration_days
#           }
#         Without this, every apply you ever run keeps its old state version
#         forever. Cheap, but unbounded is still unbounded.

# TODO(7) aws_s3_bucket_policy.state    <- DESIGN CHOICE: include it or don't
#         A policy with a single Deny statement: deny "s3:*" on the bucket and
#         its objects when `aws:SecureTransport` is "false".
#         Build it with data "aws_iam_policy_document" the way you did in
#         01-iam-lab, not raw jsonencode.
#         What it buys you: nothing today (the AWS SDK always uses TLS). It is
#         a compliance control that auditors and Security Hub look for. Include
#         it if you want the production shape; skip it if you'd rather keep
#         bootstrap minimal. Either is defensible - just decide on purpose.

# TODO(8) See outputs.tf
