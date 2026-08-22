# 09.3 Security phase 2 — S3 OBJECT LOCK (WORM: write-once-read-many)
#
# Object Lock stops an object version being deleted or overwritten, either for a
# fixed period (retention) or indefinitely (legal hold). It's the "regulatory
# compliance / cannot be tampered with" answer — SEC 17a-4, FINRA, ransomware
# protection.
#
# ⚠️ DELIBERATE CHOICE: GOVERNANCE mode, 1-day retention.
#    COMPLIANCE mode cannot be deleted by ANYONE — "the only way to delete an
#    object under compliance mode before its retention date expires is to delete
#    the associated AWS account" (AWS docs, verbatim). That is not something to
#    put in a lab account. GOVERNANCE is overridable with the right permission,
#    so this bucket stays destroyable.
#
# Note: Terraform does NOT upload any object here on purpose. If you upload one
# during the demo below, it is locked for 1 day and `terraform destroy` will fail
# on that bucket unless you delete the object with the bypass header (shown at
# the bottom). Keep that in mind before uploading.

resource "aws_s3_bucket" "locked" {
  bucket = "saa-c03-locked-${data.aws_caller_identity.current.account_id}"

  # Create-time attribute — changing it forces a NEW bucket. Object Lock is not
  # something you casually toggle on an existing bucket.
  object_lock_enabled = true

  # No force_destroy: an object under retention would refuse to delete anyway,
  # and silently forcing past a WORM lock is exactly the wrong habit to build.

  tags = {
    Name = "object-lock-demo"
  }
}

# Object Lock REQUIRES versioning — it locks a specific object VERSION, so there
# has to be versioning for a version to exist. AWS enables it implicitly with
# object_lock_enabled, but declaring it keeps Terraform's view honest.
resource "aws_s3_bucket_versioning" "locked" {
  bucket = aws_s3_bucket.locked.id

  versioning_configuration {
    status = "Enabled"
  }
}

# The DEFAULT retention applied to every object put in this bucket.
# An object can also carry its own retention, which overrides this.
resource "aws_s3_bucket_object_lock_configuration" "locked" {
  bucket = aws_s3_bucket.locked.id

  rule {
    default_retention {
      mode = "GOVERNANCE" # vs COMPLIANCE — see the warning at the top
      days = 1
    }
  }

  depends_on = [aws_s3_bucket_versioning.locked]
}

# ---------------------------------------------------------------------------
# DEMO (CLI — nothing to apply):
#
#   L=$(terraform output -raw locked_bucket)
#
#   # 1. Upload — it is now locked for 1 day by the bucket's default retention
#   aws s3 cp data.txt s3://$L/locked.txt
#
#   # 2. See the lock AWS applied
#   aws s3api head-object --bucket $L --key locked.txt \
#     --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
#
#   # 3. Try a PERMANENT delete (with a version id) -> 403 AccessDenied
#   VID=$(aws s3api list-object-versions --bucket $L --prefix locked.txt \
#          --query 'Versions[0].VersionId' --output text)
#   aws s3api delete-object --bucket $L --key locked.txt --version-id $VID
#
#   # 4. THE NUANCE: a SIMPLE delete (no version id) SUCCEEDS with 200 OK —
#   #    it just adds a delete marker. The locked version is untouched
#   #    underneath. The object "disappears" but nothing was destroyed.
#   aws s3 rm s3://$L/locked.txt
#   aws s3api list-object-versions --bucket $L    # version still there + marker
#
#   # 5. CLEAN UP (needs s3:BypassGovernanceRetention). This is the whole point
#   #    of GOVERNANCE vs COMPLIANCE — an authorised user can override.
#   aws s3api delete-object --bucket $L --key locked.txt --version-id $VID \
#     --bypass-governance-retention
#
# If step 5 fails, the bucket simply won't destroy until the 1-day retention
# expires. That is Object Lock working correctly, not a bug.
# ---------------------------------------------------------------------------
