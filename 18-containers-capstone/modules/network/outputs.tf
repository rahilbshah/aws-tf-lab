# ==========================================================================
# The module's public API. Callers can use ONLY what you export here.
#
# Be deliberate: every output is a promise you have to keep. Export what a
# caller genuinely needs to wire the next layer, not everything you happen to
# have made.
# ==========================================================================

# TODO(14) Export at minimum:
#
#   vpc_id                — everything downstream needs it
#   vpc_cidr_block        — for security group rules that allow "the VPC"
#   public_subnet_ids     — the ALB goes here          (list, not the map)
#   private_subnet_ids    — the ECS tasks go here
#   isolated_subnet_ids   — RDS and ElastiCache subnet groups go here
#   azs                   — so the caller can size things per-AZ
#
#   Convert the for_each maps to lists with values(...) - callers want
#   [id, id], and aws_lb.subnets and aws_db_subnet_group.subnet_ids both take
#   a list. Use a sorted, deterministic ordering so a plan never churns:
#       value = [for az in local.azs : aws_subnet.public[az].id]
#
#   Consider ALSO exporting nat_gateway_public_ips. Not needed to wire
#   anything, but when a third party asks you to allowlist your egress IPs -
#   and one eventually will - that is the answer, and it is nice to have it
#   printed rather than hunted for in the console.
#
# WHAT NOT TO EXPORT: route table IDs, the IGW, individual subnet objects.
# If a caller needs those, the thing they are trying to do probably belongs
# inside this module.

output "vpc_id" {
  description = "The VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The VPC's CIDR block, for security group rules scoped to \"the whole VPC\"."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs, one per AZ. The ALB and NAT gateways live here."
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs, one per AZ. ECS tasks live here."
  value       = [for az in local.azs : aws_subnet.private[az].id]
}

output "isolated_subnet_ids" {
  description = "Isolated subnet IDs, one per AZ. RDS and ElastiCache subnet groups live here."
  value       = [for az in local.azs : aws_subnet.isolated[az].id]
}

output "azs" {
  description = "The availability zones this VPC was built across, in order."
  value       = local.azs
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT gateways, for allowlisting with third parties. Empty if nat_gateway_count is 0."
  value       = aws_eip.nat[*].public_ip
}
