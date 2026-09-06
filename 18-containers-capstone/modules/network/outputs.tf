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
