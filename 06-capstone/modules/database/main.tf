# DATABASE MODULE — RDS in the private data subnets, reachable ONLY from the app tier.
# You know RDS from work, so this is mostly wiring + the exam-relevant knobs.
# No provider block; drive from var.*.
#
# Build:
#   DB SUBNET GROUP (tells RDS which subnets it may live in — must span 2+ AZs):
#   - aws_db_subnet_group.this   subnet_ids = var.data_subnet_ids, name + tags
#
#   DB SECURITY GROUP (the last link in the internet->alb->app->db chain):
#   - aws_security_group.db      in var.vpc_id, description + Name tag
#   - aws_vpc_security_group_ingress_rule.db
#       from_port/to_port = var.db_port, ip_protocol = "tcp",
#       referenced_security_group_id = var.app_sg_id   <-- ONLY the app tier, not a CIDR
#   - aws_vpc_security_group_egress_rule.db  (all egress, or omit — RDS rarely needs it)
#
#   THE DATABASE:
#   - aws_db_instance.this
#       engine               = "postgres" (or "mysql"),
#       instance_class       = var.instance_class,
#       allocated_storage    = 20,
#       db_subnet_group_name = aws_db_subnet_group.this.name,
#       vpc_security_group_ids = [aws_security_group.db.id],
#       username             = var.db_username,
#       password             = var.db_password,   # sensitive var — never hardcode
#       port                 = var.db_port,
#       multi_az             = false,             # true = HA but NOT Free-Tier; exam knows this
#       publicly_accessible  = false,             # keep it private — it's in a data subnet
#       skip_final_snapshot  = true,              # learning only; prod = false + final snapshot
#       storage_encrypted    = true               # good practice; KMS default key
#
# Then fill outputs.tf: db_endpoint + db_sg_id.
#
# Exam nuances to know (you'll build single-AZ for cost, but know these):
#   - Multi-AZ = synchronous standby in another AZ for FAILOVER (HA), NOT for reads.
#   - Read Replicas = async copies for READ SCALING (can be cross-region).
#   - Encryption at rest must be set at creation; you can't encrypt an existing
#     unencrypted RDS in place (snapshot -> copy w/ encryption -> restore).

resource "aws_db_subnet_group" "this" {
  subnet_ids = var.data_subnet_ids
}

resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Data tier: allows DB port only from the app security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db" {
  from_port                    = var.db_port
  to_port                      = var.db_port
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.app_sg_id
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "db" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all protocols -> must NOT set from_port/to_port
  security_group_id = aws_security_group.db.id
}

resource "aws_db_instance" "this" {
  engine                 = "postgres"
  instance_class         = var.instance_class
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  username               = var.db_username
  password               = var.db_password
  port                   = var.db_port
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true
}
