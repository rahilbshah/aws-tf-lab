# ==========================================================================
# PHASE 4 — RDS + ElastiCache in the isolated tier, and the password Terraform
# never sees.
#
# COST: db.t3.micro ~$0.017/hr, cache.t3.micro ~$0.017/hr. Both bill while up.
# RDS takes ~5-10 minutes to create. Destroy needs skip_final_snapshot = true
# or it refuses.
# ==========================================================================

# TODO(31) aws_db_subnet_group.this         subnet_ids = [isolated_a, isolated_b]
#          RDS requires subnets in 2+ AZs even for single-AZ. Isolated ones. This
#          is the moment the isolated tier earns its keep.

# TODO(32) aws_db_instance.this
#          identifier = var.name, engine = "postgres", instance_class = var.db_instance_class,
#          allocated_storage = 20, db_name = var.db_name, username = var.db_username,
#          db_subnet_group_name = (31), vpc_security_group_ids = [db SG],
#          publicly_accessible = false, multi_az = false, skip_final_snapshot = true,
#          storage_encrypted = true,
#
#          manage_master_user_password = true       <- THE LINE
#
#          No `password` argument. None. RDS generates the password, stores it in
#          Secrets Manager, and rotates it. Terraform never holds it, state never
#          holds it, no tfvars holds it. The instance exposes
#          master_user_secret[0].secret_arn, and that ARN is all you ever touch.
#          This is the production answer to "how do I not have the DB password in
#          my Terraform", and it is one argument.
#
#          DESIGN CHOICE, worth knowing: the alternative is password_wo +
#          password_wo_version (Terraform 1.11+ write-only args) with an
#          ephemeral random_password. Also keeps it out of state, but YOU own
#          rotation. Managed is simpler here and is what the exam means by
#          "use Secrets Manager with RDS".

# TODO(33) aws_elasticache_subnet_group.this   subnet_ids = [isolated_a, isolated_b]
# TODO(34) aws_elasticache_cluster.this
#          cluster_id = var.name, engine = "redis", node_type = var.cache_node_type,
#          num_cache_nodes = 1, port = 6379, subnet_group_name = (33),
#          security_group_ids = [cache SG]
#          Single node, no replication - this is a cache, and the lab is about
#          reaching it from the private tier, not about Redis HA.

# ---- now wire it into the task definition (edit TODO 29 and 27) -------------
# TODO(35) In the container's `environment`, add:
#            DB_HOST   = aws_db_instance.this.address        (address, NOT endpoint - endpoint includes :port)
#            DB_NAME   = var.db_name
#            DB_USER   = var.db_username
#            REDIS_HOST = aws_elasticache_cluster.this.cache_nodes[0].address
#
# TODO(36) In the container definition, add:
#            secrets = [{
#              name      = "DB_PASSWORD"
#              valueFrom = "${aws_db_instance.this.master_user_secret[0].secret_arn}:password::"
#            }]
#          That ":password::" suffix is AWS's documented JSON-key syntax
#          (arn:json-key:version-stage:version-id). The secret is a JSON object
#          {username, password}; this says "just the password field, current version".
#
# TODO(37) aws_iam_role_policy.execution_read_secret   on the EXECUTION role (27)
#            Allow secretsmanager:GetSecretValue on exactly that secret ARN.
#            (KMS: the secret uses the AWS-managed key, so no kms:Decrypt needed.)
#
#          Why the EXECUTION role, not the task role: the agent fetches the secret
#          and injects it BEFORE your container starts. Your code never calls
#          Secrets Manager; it just reads an env var. If you put this on the task
#          role instead, the task fails to start with "unable to retrieve secrets".
#
# PHASE 4 IS DONE when:  curl /db     -> {"db":"postgres","rows":N}  and N climbs each call
#                        curl /cache  -> {"cache":"redis","counter":N}
#                        and:  grep -r password *.tf   returns NOTHING
#                        and:  terraform state show aws_db_instance.this | grep -i password  shows only the secret ARN

resource "aws_db_subnet_group" "this" {
  subnet_ids = [aws_subnet.isolated_a.id, aws_subnet.isolated_b.id]
}

resource "aws_db_instance" "this" {
  identifier             = var.name
  engine                 = "postgres"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true
  storage_encrypted      = true

  manage_master_user_password = true
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-cache"
  subnet_ids = [aws_subnet.isolated_a.id, aws_subnet.isolated_b.id]
}

resource "aws_elasticache_cluster" "this" {
  cluster_id         = var.name
  engine             = "redis"
  node_type          = var.cache_node_type
  num_cache_nodes    = 1
  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.cache.id]
}
