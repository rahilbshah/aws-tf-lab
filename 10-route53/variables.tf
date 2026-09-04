variable "zone_name" {
  description = <<-EOT
    The domain for the hosted zone. Uses the RFC 2606 reserved TLD `.example`,
    which is guaranteed never to be delegated to anyone — so this can never
    collide with a real domain or squat on someone's name. Nothing on the
    internet can resolve it; we query the assigned nameservers directly.
  EOT
  type        = string
  default     = "saa-c03-lab.example"
}

variable "name_prefix" {
  description = "Prefix for the S3 buckets backing the failover demo."
  type        = string
  default     = "saa-c03-r53"
}

variable "record_ttl" {
  description = "TTL in seconds. Deliberately low so failover is observable in minutes, not hours."
  type        = number
  default     = 60
}
