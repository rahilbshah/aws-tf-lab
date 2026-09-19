# ==========================================================================
# PHASE 5 — an uploads bucket, reached through the TASK role.
# This is the first thing YOUR CODE does against an AWS API, so it is where
# the task role finally gets a permission. COST: ~nothing.
# ==========================================================================

# TODO(38) aws_s3_bucket.uploads
#          bucket = "${var.name}-uploads-${account id from data.aws_caller_identity}"
#          force_destroy = true     (so destroy works with objects inside)
# TODO(39) aws_s3_bucket_public_access_block.uploads   all four = true
# TODO(40) aws_s3_bucket_server_side_encryption_configuration.uploads   AES256

# ---- wire it in --------------------------------------------------------------
# TODO(41) aws_iam_role_policy.task_s3   on the TASK role (28)
#            Allow s3:PutObject on "${bucket arn}/*"   — that is all the app does.
#          Not s3:*, not the bucket ARN without /*, not GetObject. One action, one
#          resource. If a later feature needs reads, add s3:GetObject THEN.
#
# TODO(42) In the container `environment`, add  UPLOAD_BUCKET = the bucket id.
#
# PHASE 5 IS DONE when:  curl -XPOST http://<alb>/upload -d 'hello'  -> {"uploaded": "uploads/..."}
#                        aws s3 ls s3://<bucket>/uploads/              -> the object
#
# And a thing to notice: that PutObject went S3 gateway endpoint -> S3, never
# through the NAT gateway. Check the NAT's BytesOutToDestination metric in
# CloudWatch: it does not move when you upload. That is phase 1's endpoint
# saving you $0.045/GB, visibly.
