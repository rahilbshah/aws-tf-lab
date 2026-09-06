# ==========================================================================
# Routing. This file is where the three tiers actually become three tiers.
#
# Everything before this created subnets that are indistinguishable from each
# other. A subnet is public or private or isolated ONLY because of the route
# table attached to it. Nothing else. You proved this to yourself in 05-vpc;
# here it is load-bearing.
# ==========================================================================

# TODO(9)  aws_route_table.public   — ONE, shared by all public subnets
#          route { cidr_block = "0.0.0.0/0", gateway_id = the IGW }
#          One is enough: every public subnet wants the same answer, and the
#          IGW is not AZ-scoped.

# TODO(10) aws_route_table.private  — ONE PER AZ, for_each over local.azs
#          Default route 0.0.0.0/0 -> the NAT for that AZ (see the indexing
#          note in nat.tf).
#
#          Why per-AZ even when there is only one NAT: so that raising
#          nat_gateway_count from 1 to 2 changes only WHICH NAT each table
#          points at, not the shape of the config. The dev/prod difference
#          becomes a single number in a tfvars file, which is the entire
#          point of building this as a module.
#
#          Handle nat_gateway_count = 0: no default route at all. A dynamic
#          block, or count on a separate aws_route, both work - pick one.

# TODO(11) aws_route_table.isolated — ONE, shared by all isolated subnets
#          NO ROUTE BLOCK. None. Not to the IGW, not to the NAT.
#
#          The only entry will be the VPC-local route AWS adds automatically,
#          plus the S3 endpoint association from endpoints.tf. This is the
#          resource that makes the database unreachable from, and unable to
#          reach, the internet. It is the most important empty resource you
#          will write in this project.

# TODO(12) aws_route_table_association — three sets, all for_each over AZs:
#            public subnets   -> the single public RT
#            private subnets  -> that AZ's private RT
#            isolated subnets -> the single isolated RT
