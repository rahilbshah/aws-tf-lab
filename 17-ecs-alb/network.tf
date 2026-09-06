# ==========================================================================
# 17-ecs-alb — ALB in front of Fargate tasks running nginxdemos/hello
#
# The whole point of this lab is one observable: hit the ALB, refresh, and
# watch the "Server address" on the page change between your two tasks.
# Everything below exists to make that happen.
#
# BUILD ORDER: this file first, applied and clean, before anything else.
# Nothing else can be written until the VPC and subnets exist.
#
# COST, plainly. This lab bills while it is up:
#   NAT gateway   $0.045/hr  + $0.045/GB processed   <- the expensive one
#   ALB           $0.0225/hr + LCUs
#   2 Fargate tasks (0.25 vCPU / 0.5 GB)  ~$0.025/hr total
#   Public IPv4 (ALB nodes + NAT EIP)     ~$0.015/hr
#   ~= 12 cents/hour. A 3-hour session is under 40 cents. Destroy at the end.
#
# WHY A NAT GATEWAY AT ALL: the tasks sit in private subnets and must reach
# Docker Hub to pull the image. Private subnet + no NAT = the task never
# starts, and the failure is a stopped task with a CannotPullContainerError,
# not a Terraform error. You would be debugging the wrong layer.
# ==========================================================================

# TODO(1) data.aws_availability_zones.available
#         state = "available". Use it to place subnets instead of hardcoding
#         "us-east-1a" - same habit as 05-vpc.

# TODO(2) aws_vpc.this
#         cidr_block = var.vpc_cidr, enable_dns_hostnames = true,
#         enable_dns_support = true. DNS hostnames matter here: ECS service
#         discovery and the ALB both lean on DNS.

# TODO(3) aws_subnet.public  — two of them, one per AZ.
#         count or for_each over var.public_subnet_cidrs;
#         availability_zone from the data source in (1);
#         map_public_ip_on_launch = true.
#         An ALB REQUIRES at least two subnets in two different AZs. This is
#         not advice, it is a hard validation error at apply time.

# TODO(4) aws_subnet.private — two of them, one per AZ, same CIDR pattern.
#         No map_public_ip_on_launch. The tasks go here.

# TODO(5) aws_internet_gateway.this
#         vpc_id only. Attaching it is what makes the public subnets public -
#         a subnet is "public" because of its ROUTE TABLE, nothing else.

# TODO(6) aws_eip.nat
#         domain = "vpc"  (not the old `vpc = true`, which is deprecated on v6)

# TODO(7) aws_nat_gateway.this
#         allocation_id = the EIP from (6)
#         subnet_id     = one of the PUBLIC subnets from (3)
#         depends_on    = [aws_internet_gateway.this]
#
#         DESIGN CHOICE, flagged: one NAT gateway, not one per AZ. Production
#         wants one per AZ so an AZ failure doesn't cut egress for the other.
#         Here that would double the biggest line on the bill for a lab you
#         destroy in three hours. Build one; know why prod builds two.

# TODO(8) aws_route_table.public   — route 0.0.0.0/0 -> the IGW
#         aws_route_table.private  — route 0.0.0.0/0 -> the NAT gateway
#         DESIGN CHOICE: inline `route` blocks on the route table, or separate
#         aws_route resources. Pick one place and stay there - mixing the two
#         for the same table makes Terraform fight itself on every plan.

# TODO(9) aws_route_table_association — public subnets -> public RT,
#         private subnets -> private RT. Four associations total.
#
#   Before you move on: the NAT gateway sits in a PUBLIC subnet but exists to
#   serve the PRIVATE ones. Say why out loud. If that sentence feels shaky,
#   re-read 05-vpc-core before continuing - everything after this assumes it.
