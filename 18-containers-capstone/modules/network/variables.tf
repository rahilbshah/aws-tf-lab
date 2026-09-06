variable "name" {
  description = "Name prefix for every resource in this module, e.g. \"capstone-dev\"."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for the VPC. A /16 gives room for 3 tiers x N AZs of /24s."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && tonumber(split("/", var.vpc_cidr)[1]) <= 20
    error_message = "vpc_cidr must be valid CIDR and /20 or larger (smaller prefix number) to fit the subnet plan."
  }
}

variable "az_count" {
  description = <<-EOT
    How many Availability Zones to spread across. 2 is the minimum an ALB will
    accept. 3 is what you would use in production for a service that must
    survive one AZ loss with capacity to spare.
  EOT
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3. One AZ cannot host an ALB; more than 3 is not worth the NAT bill here."
  }
}

variable "nat_gateway_count" {
  description = <<-EOT
    THE COST LEVER OF THIS ENTIRE PROJECT. NAT gateways bill $0.045/hr each
    plus $0.045/GB processed (verified 2026-09-06).

      0  - no NAT at all. Private tasks cannot reach the internet. Only viable
           if every dependency is reachable via a VPC endpoint.
      1  - one shared NAT. ~$32/month. Cross-AZ traffic to reach it is billed,
           and losing that AZ cuts egress for every private subnet.
      2+ - one per AZ. True HA, and double the bill.

    dev should be 1. prod should equal az_count. That difference is most of
    what separates the two environments.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = var.nat_gateway_count >= 0 && var.nat_gateway_count <= 3
    error_message = "nat_gateway_count must be between 0 and 3."
  }
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch. Useful for debugging REJECTs; costs ingestion + storage. Off for dev."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention for flow logs, when enabled."
  type        = number
  default     = 7
}
