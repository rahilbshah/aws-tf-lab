# TODO(8) output "state_bucket"
#         value = the bucket id/name. You will paste this into every backend
#         block in live/, so make it easy to copy.
#
#         Also useful: output "backend_config" as a here-doc string that prints
#         the exact backend block to paste. Optional, but you'll type it four
#         times otherwise.
#
# ==========================================================================
# AFTER THIS APPLIES - the migration is the actual lesson
#
# Do NOT do this yet. Apply bootstrap first, confirm the bucket exists with
# versioning on, then come back and we'll walk the migration together on one
# small existing lab before touching anything that matters.
#
# The shape of it, so you know where we're going:
#
#   1. Add a backend block to a config that currently has local state:
#
#        terraform {
#          backend "s3" {
#            bucket       = "<the output above>"
#            key          = "<something>/terraform.tfstate"
#            region       = "us-east-1"
#            encrypt      = true
#            use_lockfile = true      # native S3 locking, NO DynamoDB table
#          }
#        }
#
#   2. terraform init -migrate-state
#      Terraform notices the backend changed, and offers to copy your existing
#      local state up. Say yes. Read what it prints before you answer.
#
#   3. Confirm terraform plan says "No changes". If state migrated correctly,
#      nothing about your infrastructure changed - only where the bookkeeping
#      lives.
#
# THE OBSERVABLE TO WATCH FOR:
#   During a long apply, list the bucket in another terminal:
#       aws s3 ls s3://<bucket>/<key-prefix>/
#   You will see a `.tflock` object appear for the duration of the apply and
#   vanish when it finishes. That object IS the lock. It is what replaced the
#   DynamoDB table every tutorial still tells you to build. Watch it appear
#   once and you will never wonder what use_lockfile actually does.
# ==========================================================================
