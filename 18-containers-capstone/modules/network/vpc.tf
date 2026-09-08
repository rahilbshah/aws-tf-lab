# ==========================================================================
# modules/network — a three-tier VPC
#
# This is your first real module, so two things are new at once. Read this
# header before writing anything.
#
# WHAT MAKES THIS A MODULE, MECHANICALLY:
#   - variables.tf is its INPUT API. Callers set these.
#   - outputs.tf is its OUTPUT API. Callers can only use what you export.
#   - No provider block, no backend block (see versions.tf).
#   - It has no state of its own. Its resources land in live/dev's state,
#     addressed as module.network.aws_vpc.this
#
# THE DESIGN GOAL: three tiers, not two.
#
#   PUBLIC    ALB and NAT gateways.  Route 0.0.0.0/0 -> IGW.
#   PRIVATE   ECS tasks.             Route 0.0.0.0/0 -> NAT.
#   ISOLATED  RDS and ElastiCache.   NO 0.0.0.0/0 ROUTE AT ALL.
#
# That third tier is the step up from 17-ecs-alb. Your database will be
# unable to reach the internet as a matter of ROUTING, not as a matter of a
# security group rule someone can edit. If a dependency is compromised and
# tries to phone home, there is no path. Say that sentence back to yourself
# before you write the isolated route table - it is the reason it exists.
#
# BUILD ORDER: vpc.tf -> subnets.tf -> nat.tf -> routing.tf -> endpoints.tf
# -> outputs.tf. Continuously numbered 1..13 across those files.
#
# COST while this module is applied, with nat_gateway_count = 1:
#   NAT gateway   $0.045/hr  (~$32/mo)   <- essentially the whole bill
#   EIP on it     $0.005/hr
#   VPC, subnets, route tables, IGW, S3 gateway endpoint:  FREE
#   ~5 cents/hour. With nat_gateway_count = 0 it is genuinely $0.
# ==========================================================================

# TODO(1) data.aws_availability_zones.available
#         state = "available"
#
#         Then a `locals` block, because you need a STABLE ORDERED list:
#           locals {
#             azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
#           }
#         Everything else keys off local.azs. Slicing a sorted list keeps AZ
#         assignment deterministic - without it, a reordered API response
#         could move subnets between AZs on a later plan.

# TODO(2) aws_vpc.this
#         cidr_block           = var.vpc_cidr
#         enable_dns_support   = true
#         enable_dns_hostnames = true
#         tags = { Name = "${var.name}-vpc" }
#
#         DNS hostnames are not optional here: RDS endpoints, VPC endpoint
#         private DNS and ECS service discovery all depend on them.

# TODO(3) aws_internet_gateway.this
#         vpc_id, tags. One per VPC, no arguments worth thinking about.

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name}-ig"
  }
}
