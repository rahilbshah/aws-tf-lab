# ==========================================================================
# PHASE 1a — the network. Three tiers, written out explicitly.
#
# This is 17-ecs-alb's network plus ONE new idea: an ISOLATED tier for the
# databases. Public = ALB + NAT. Private = ECS tasks. Isolated = RDS and
# ElastiCache, with NO route to the internet at all - not even via NAT.
# The database cannot reach the internet as a matter of ROUTING, not as a
# security-group promise someone can edit later. That is the production
# pattern, and it costs you exactly two subnets and one empty route table.
#
# Explicit resources, two AZs, no loops. Same style you already built.
#
# COST: the NAT gateway is $0.045/hr + $0.045/GB. Everything else here is free.
# One NAT, not two - production wants one per AZ, but that doubles the biggest
# line on the bill for a lab you destroy each session.
# ==========================================================================

# TODO(1)  data.aws_availability_zones.available   state = "available"

# TODO(2)  aws_vpc.this
#          cidr_block = var.vpc_cidr, enable_dns_support = true,
#          enable_dns_hostnames = true   (RDS endpoints need DNS hostnames)

# TODO(3)  aws_internet_gateway.this   vpc_id

# TODO(4)  aws_subnet.public_a     cidr var.public_subnet_cidrs[0], AZ names[0], map_public_ip_on_launch = true
# TODO(5)  aws_subnet.public_b     cidr var.public_subnet_cidrs[1], AZ names[1], map_public_ip_on_launch = true
# TODO(6)  aws_subnet.private_a    cidr var.private_subnet_cidrs[0], AZ names[0]
# TODO(7)  aws_subnet.private_b    cidr var.private_subnet_cidrs[1], AZ names[1]
# TODO(8)  aws_subnet.isolated_a   cidr var.isolated_subnet_cidrs[0], AZ names[0]
# TODO(9)  aws_subnet.isolated_b   cidr var.isolated_subnet_cidrs[1], AZ names[1]
#          Tag each with Tier = "public" / "private" / "isolated". At 2am in the
#          console, "which of these can reach the internet" is the first question.

# TODO(10) aws_eip.nat            domain = "vpc"
# TODO(11) aws_nat_gateway.this   allocation_id = the EIP, subnet_id = public_a,
#                                 depends_on = [aws_internet_gateway.this]

# TODO(12) aws_route_table.public     route 0.0.0.0/0 -> the IGW
# TODO(13) aws_route_table.private    route 0.0.0.0/0 -> the NAT gateway
# TODO(14) aws_route_table.isolated   NO route block. None. This empty resource is
#          the most important thing in the file - it is what makes the tier isolated.

# TODO(15) aws_route_table_association x6 — each subnet to its tier's table.
#          Six near-identical blocks is fine. You have done this; it reads clearly.

# TODO(16) aws_vpc_endpoint.s3
#          vpc_id, service_name = "com.amazonaws.us-east-1.s3",
#          vpc_endpoint_type = "Gateway",
#          route_table_ids = [private RT, isolated RT]
#          FREE. S3 traffic from the private tier stops going through the NAT
#          (and being billed per GB), and the ISOLATED tier gets S3 access with no
#          internet route at all - which is how RDS snapshots and ECR image
#          layers work from a subnet that cannot reach the internet.
#
#   Before moving on: the isolated route table has no default route. Say out
#   loud what that means for a compromised dependency inside RDS trying to
#   phone home. That sentence is the reason the tier exists.

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "igw-18"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-a"
    Tier = "public"
  }

}
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-b"
    Tier = "public"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-a"
    Tier = "private"
  }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-b"
    Tier = "private"
  }
}

resource "aws_subnet" "isolated_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.isolated_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "isolated-b"
    Tier = "isolated"
  }
}
resource "aws_subnet" "isolated_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.isolated_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "isolated-b"
    Tier = "isolated"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "isolated-rt"
  }
}

resource "aws_route_table_association" "isolated_a" {
  subnet_id      = aws_subnet.isolated_a.id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_route_table_association" "isolated_b" {
  subnet_id      = aws_subnet.isolated_b.id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.isolated.id]
}
