variable "name_prefix" {
  description = "Prefix for every named resource in this lab. IAM names are account-global, so keep it distinctive."
  type        = string
  default     = "saa-c03-iam-lab"
}

variable "allowed_prefix" {
  description = "The one S3 key prefix this role is allowed to read and list. Trailing slash included."
  type        = string
  default     = "reports/"
}
