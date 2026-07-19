# RDS — a PostgreSQL instance, best-practice config.
#
# Build:
#   - aws_security_group.rds       vpc_id = aws_vpc.this.id, description + Name "rds-sg"
#   - aws_vpc_security_group_ingress_rule.rds
#        referenced_security_group_id = aws_security_group.client.id   (app tier ONLY)
#        ip_protocol = "tcp", from_port/to_port = 5432
#     (no egress rule needed for RDS; it doesn't initiate outbound)
#
#   - aws_db_instance.this
#        identifier             = "rds-lab"
#        engine                 = "postgres"
#        instance_class         = "db.t3.micro"        # Free-Tier eligible, single-AZ
#        allocated_storage      = 20
#        storage_type           = "gp3"
#        db_subnet_group_name   = aws_db_subnet_group.this.name
#        vpc_security_group_ids = [aws_security_group.rds.id]
#        username               = "dbadmin"            # not "root" (reserved)
#        password               = var.db_password      # sensitive, from tfvars
#        # --- best practices ---
#        storage_encrypted       = true                # at rest (creation-time only!)
#        publicly_accessible     = false               # private
#        multi_az                = false               # true = HA but not Free-Tier; know the flag
#        backup_retention_period = 7                   # enables automated backups + PITR (0 = off)
#        deletion_protection     = false               # true in prod; false so we can destroy
#        skip_final_snapshot     = true                # false in prod (take a final snapshot)
#        auto_minor_version_upgrade = true
#        apply_immediately       = true                # lab convenience; careful in prod
#
# Note: enabling backup_retention_period > 0 is what turns on automated backups /
# point-in-time recovery. multi_az flips it to a synchronous standby (HA, not readable).


resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allows Postgres/MySQL access only from the client SG"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds" {
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.rds.id
  from_port                    = 5432
  to_port                      = 5432
  description                  = "DB access from app tier"
  referenced_security_group_id = aws_security_group.client.id
}

resource "aws_db_instance" "this" {
  identifier                 = "rds-lab"
  engine                     = "postgres"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  storage_type               = "gp3"
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  username                   = "dbadmin"
  password                   = var.db_password
  storage_encrypted          = true
  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 1 # Free-Tier "Free Plan" caps this; 1 keeps automated backups/PITR on (was 7)
  deletion_protection        = false
  skip_final_snapshot        = true
  auto_minor_version_upgrade = true
  apply_immediately          = true

}
