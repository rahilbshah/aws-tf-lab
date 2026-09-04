variable "name_prefix" {
  description = "Prefix for the origin bucket name."
  type        = string
  default     = "saa-c03-cf"
}

variable "html_ttl" {
  description = <<-EOT
    Default TTL for the HTML entry point. Deliberately short: the HTML is the
    only thing that must change quickly, and it is tiny. Fingerprinted assets
    under /static/* get the long managed TTL instead.
  EOT
  type        = number
  default     = 60
}
