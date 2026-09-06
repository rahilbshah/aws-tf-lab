variable "region" {
  description = "AWS region. Kept as a variable so prod could differ, though both are us-east-1 here."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for this environment's resources."
  type        = string
  default     = "capstone-dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR for this environment. Keep dev and prod NON-OVERLAPPING - the day you want to peer them, overlapping CIDRs make it impossible."
  type        = string
  default     = "10.10.0.0/16"
}

variable "az_count" {
  description = "AZs to span. 2 in dev."
  type        = number
  default     = 2
}

variable "nat_gateway_count" {
  description = "1 in dev (~$32/mo). prod will set this to az_count."
  type        = number
  default     = 1
}

variable "enable_flow_logs" {
  description = "Off in dev - ingestion costs money and you are not debugging anything yet."
  type        = bool
  default     = false
}
