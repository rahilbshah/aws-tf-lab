variable "state_bucket_prefix" {
  description = <<-EOT
    Prefix for the state bucket name. Your AWS account ID is appended to make it
    globally unique, because S3 bucket names share one namespace across every
    AWS account on earth. Using the account ID keeps it deterministic - a random
    suffix would work too but you'd have to look it up every time you write a
    backend block.
  EOT
  type        = string
  default     = "tfstate"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}[a-z0-9]$", var.state_bucket_prefix))
    error_message = "Bucket prefix must be lowercase alphanumeric or hyphens, and cannot start or end with a hyphen (S3 bucket naming rules)."
  }
}

variable "noncurrent_version_expiration_days" {
  description = <<-EOT
    How long to keep OLD state versions after they are superseded. Versioning is
    your undo button for a bad apply, so this is "how far back can I roll the
    state". 90 is a reasonable default; state files are tiny so this costs
    approximately nothing.
  EOT
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 30
    error_message = "Keep at least 30 days of state history - shorter than that and a mistake found late is unrecoverable."
  }
}
