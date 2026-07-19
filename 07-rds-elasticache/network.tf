# NETWORK — a minimal PRIVATE-only VPC. RDS and ElastiCache need no internet
# egress, so there is NO IGW and NO NAT here (that keeps it free). Just a VPC,
# two private subnets across two AZs, and the two subnet groups the data
# services require.
#
# Build:
#   - data.aws_availability_zones.available   state = "available"
#   - aws_vpc.this                            cidr = var.vpc_cidr, enable_dns_* = true, Name tag
#   - aws_subnet.private_a / private_b        the two var.private_subnet_cidrs across 2 AZs,
#                                             NO map_public_ip_on_launch (private), Name tags
#
#   SUBNET GROUPS (each data service needs its subnets declared as a group, 2+ AZs):
#   - aws_db_subnet_group.this                subnet_ids = both private subnets, Name tag
#   - aws_elasticache_subnet_group.this       subnet_ids = both private subnets
#
#   CLIENT SG (represents an app tier; RDS + Redis will allow ONLY this SG — the
#   SG-to-SG pattern. Nothing is attached to it here; it demonstrates the shape and
#   is what you'd put on your app instances):
#   - aws_security_group.client               vpc_id = aws_vpc.this.id, description + Name tag
#
# Best practice: data tier in PRIVATE subnets, reachable only from the app tier's
# SG — never publicly_accessible, never 0.0.0.0/0.

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-07"
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

resource "aws_db_subnet_group" "this" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "my-elasticache-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

}

resource "aws_security_group" "client" {
  name        = "client-sg"
  description = "Represents the app tier; attach this SG to app/EC2/ECS/Lambda resources that need DB/cache access"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "client-sg"
  }
}
