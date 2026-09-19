# ==========================================================================
# PHASE 1b — every security group, written up front so later files just
# reference them. Use the v6-style separate rule resources you used in
# 17-ecs-alb (aws_vpc_security_group_ingress_rule / _egress_rule) - you did
# that better than my scaffold suggested last time, keep doing it.
#
# The shape is a CHAIN, and each link only trusts the previous one:
#   internet -> ALB -> app tasks -> RDS / ElastiCache
# No CIDRs between tiers. Every internal rule uses referenced_security_group_id.
# ==========================================================================

# TODO(17) aws_security_group.alb
#          ingress TCP 80 from 0.0.0.0/0   (phase 6 replaces this with
#                                           "from CloudFront only" - leave it
#                                           open for now so you can test directly)
#          egress  TCP var.container_port -> referenced_security_group_id = app SG
#          (Least privilege on egress this time: the ALB only ever talks to tasks.)

# TODO(18) aws_security_group.app       (the ECS tasks)
#          ingress TCP var.container_port from referenced_security_group_id = ALB SG
#          egress  all to 0.0.0.0/0   (needs NAT to pull the image, reach S3
#                                      via the endpoint, and reach RDS/Redis)

# TODO(19) aws_security_group.db        (RDS)
#          ingress TCP 5432 from referenced_security_group_id = app SG
#          NO egress rule needed for correctness (RDS initiates nothing) - but a
#          security group with no egress rule denies all outbound, which is
#          exactly right for an isolated database. Leave egress absent on purpose.

# TODO(20) aws_security_group.cache     (ElastiCache Redis)
#          ingress TCP 6379 from referenced_security_group_id = app SG
#          Same: no egress.
#
#   Note what 19 and 20 mean together with the isolated route table: the
#   database has no route out AND no rule allowing it out. Two independent
#   controls. If someone deletes one, the other still holds.

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "ALB tier: allows HTTP (80) from the internet"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.alb.id

  tags = {
    Name = "alb-http-from-cloudfront"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port

  tags = {
    Name = "alb-all-egress"
  }
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "App tier: allows traffic only from the ALB security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "app-http-from-alb"
  }
}

resource "aws_vpc_security_group_egress_rule" "app" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all protocols -> must NOT set from_port/to_port
  security_group_id = aws_security_group.app.id

  tags = {
    Name = "app-all-egress"
  }
}


resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "DB tier: allows traffic only from the App security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db" {
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id

  tags = {
    Name = "db-port-from-app"
  }
}

resource "aws_security_group" "cache" {
  name        = "cache-sg"
  description = "CACHE tier: allows traffic only from the App security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "cache-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "cache" {
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.cache.id
  referenced_security_group_id = aws_security_group.app.id

  tags = {
    Name = "cache-port-from-app"
  }
}
