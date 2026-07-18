# VPC MODULE — a 3-tier network (public / private-app / private-data), 2 AZs.
# You've built ~all of this in 05-vpc; adapt it here, but drive everything from
# the module's var.* inputs (no hardcoded CIDRs) and expose outputs.tf.
#
# NOTE: no provider block, no terraform block — a child module inherits the
# root's provider. Just resources, variables, outputs.
#
# Build:
#   - data.aws_availability_zones.available
#   - aws_vpc.this (var.vpc_cidr, DNS on)
#   - 6 subnets: 2 public, 2 app, 2 data (use var.*_subnet_cidrs[0]/[1] across
#     the 2 AZs). This is a strong for_each/count candidate now — 6 near-identical
#     subnets — but explicit is fine if clearer to you.
#   - aws_internet_gateway.this
#   - aws_route_table.public (0.0.0.0/0 -> IGW) + associate the 2 public subnets
#   - NAT: aws_eip + aws_nat_gateway (in a public subnet) — needed so app-tier
#     instances can pull packages / reach AWS. (This bills — destroy after.)
#   - aws_route_table.private (0.0.0.0/0 -> NAT) + associate the 4 private
#     subnets (app + data). Data subnets can share the private RT, or get their
#     own with NO NAT route if you want them fully isolated — your call.
#   - Name-tag everything.
#
# Then fill in outputs.tf so the root can read vpc_id + the 3 subnet-ID lists.

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "vpc-06"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-b"
  }
}

resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "app-a"
  }
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "app-b"
  }
}

resource "aws_subnet" "data_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "data-a"
  }
}

resource "aws_subnet" "data_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "data-b"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "igw-06"
  }
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

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data_a" {
  subnet_id      = aws_subnet.data_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "data_b" {
  subnet_id      = aws_subnet.data_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-06"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "nat-gw-06"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}
