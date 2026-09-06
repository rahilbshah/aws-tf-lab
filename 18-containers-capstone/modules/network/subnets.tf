# ==========================================================================
# Three tiers x N AZs. This is where you meet for_each properly.
#
# In 17-ecs-alb you wrote public_a, public_b, private_a, private_b as four
# near-identical resource blocks. A module cannot do that - it does not know
# how many AZs the caller wants. So: one resource block per TIER, iterating
# over AZs.
#
#   for_each = toset(local.azs)
#
# Why toset and not the list: with a list, for_each keys would be 0,1,2 and
# inserting an AZ at the front would RENUMBER everything and destroy/recreate
# subnets that did not change. Keyed by AZ NAME, the address is
# aws_subnet.public["us-east-1a"] and it is stable forever.
# That is the whole argument for for_each over count, in one sentence.
# ==========================================================================

# CIDR MATH - a design choice, decide before you write:
#
#   (a) compute them:  cidrsubnet(var.vpc_cidr, 8, N)
#       turns 10.0.0.0/16 into /24s. Scales to any az_count, no editing.
#   (b) pass them in as three list(string) variables and index by AZ.
#       explicit, greppable, but the caller must recount if az_count changes.
#
# Recommendation: (a), with an offset per tier so the tiers are readable at a
# glance in the console:
#       public   -> cidrsubnet(var.vpc_cidr, 8, index)          -> 10.0.0.x, 10.0.1.x
#       private  -> cidrsubnet(var.vpc_cidr, 8, index + 10)     -> 10.0.10.x, 10.0.11.x
#       isolated -> cidrsubnet(var.vpc_cidr, 8, index + 20)     -> 10.0.20.x, 10.0.21.x
# where index is  index(local.azs, each.key).

# TODO(4) aws_subnet.public — for_each over the AZs
#         vpc_id, availability_zone = each.key
#         cidr_block              = see the math above
#         map_public_ip_on_launch = true
#         tags = { Name = "${var.name}-public-${each.key}", Tier = "public" }

# TODO(5) aws_subnet.private — for_each over the AZs
#         Same shape. NO map_public_ip_on_launch.
#         tags Tier = "private"

# TODO(6) aws_subnet.isolated — for_each over the AZs
#         Same shape. NO map_public_ip_on_launch.
#         tags Tier = "isolated"
#
#   Tagging the tier is not decoration. When you are staring at 6 subnets in
#   the console at 2am, "which of these can reach the internet" is the first
#   question you will ask.
