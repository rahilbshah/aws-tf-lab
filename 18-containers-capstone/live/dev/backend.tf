terraform {
  backend "s3" {
    bucket = "tfstate-626210706989"
    key    = "live/dev/terraform.tfstate"
    region = "us-east-1"

    encrypt      = true
    use_lockfile = true # native S3 locking. NO dynamodb_table - deprecated.
  }
}

# The `key` is the whole environment-separation strategy. live/prod will use
# "live/prod/terraform.tfstate" in the SAME bucket. Different key = different
# state = a mistake in dev cannot touch prod. Same modules, isolated state.
#
# Note what a backend block cannot do: it takes no variables, no interpolation,
# no locals. It is read before Terraform evaluates anything. That is why the
# bucket name is hardcoded here rather than referenced from bootstrap's output,
# and why each environment gets its own directory rather than a shared config
# with a var. Terraform's own docs call this out - it is not a limitation you
# can engineer around, only one you lay out your directories to accommodate.
