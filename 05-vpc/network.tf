# 05 – VPC core two-tier network (the FREE part — build this first)
#
# All .tf files in this folder are merged by Terraform; this file just groups
# the core networking resources. Write them top-down:
#
#   LOOKUP
#   1. data.aws_availability_zones.available   – state = "available"; use .names[0]/.names[1]
#                                                instead of hardcoding "us-east-1a"
#   THE VPC
#   2. aws_vpc.this                            – cidr_block = var.vpc_cidr (10.0.0.0/16)
#                                                enable_dns_hostnames = true
#                                                enable_dns_support   = true   (public DNS now +
#                                                required for interface endpoints later)
#   SUBNETS  (4 — 2 public, 2 private, across 2 AZs)
#   3. aws_subnet.public_a / public_b          – map_public_ip_on_launch = true  <-- the "public IP"
#                                                half of what makes a subnet public
#      aws_subnet.private_a / private_b         – NO auto public IP
#      (4 near-identical blocks = the textbook for_each moment. Explicit is fine while
#       learning; we can refactor to for_each as a lesson.)
#   INTERNET GATEWAY
#   4. aws_internet_gateway.this               – vpc_id attaches it
#   PUBLIC ROUTING
#   5. aws_route_table.public                  – route 0.0.0.0/0 -> IGW  <-- the "route" half of
#                                                public. Inline route{} OR a separate aws_route —
#                                                pick ONE, don't mix (drift trap).
#   PRIVATE ROUTING
#   6. aws_route_table.private                 – NO 0.0.0.0/0 route yet. That absence IS what
#                                                makes it private. NAT (see nat.tf) adds it later.
#   ASSOCIATIONS
#   7. aws_route_table_association (x4)         – public subnets -> public RT
#                                                private subnets -> private RT
#
# Expect ~12 resources. Nothing here bills.

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-05"
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

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "private-b"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "igw-05"
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

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}