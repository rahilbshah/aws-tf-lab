# ELASTICACHE — a Redis replication group (HA), best-practice config.
# Use aws_elasticache_replication_group (NOT aws_elasticache_cluster) so you get
# a primary + replica with Multi-AZ automatic failover — the production shape.
#
# Build:
#   - aws_security_group.redis     vpc_id = aws_vpc.this.id, description + Name "redis-sg"
#   - aws_vpc_security_group_ingress_rule.redis
#        referenced_security_group_id = aws_security_group.client.id   (app tier ONLY)
#        ip_protocol = "tcp", from_port/to_port = 6379
#
#   - aws_elasticache_replication_group.this
#        replication_group_id = "redis-lab"
#        description          = "Lab Redis HA replication group"
#        engine               = "redis"                 # or "valkey"
#        node_type            = "cache.t3.micro"         # cheapest; ~cents/hr from credit
#        num_cache_clusters   = 2                        # 1 primary + 1 replica (needed for failover)
#        port                 = 6379
#        subnet_group_name    = aws_elasticache_subnet_group.this.name
#        security_group_ids   = [aws_security_group.redis.id]
#        # --- best practices ---
#        automatic_failover_enabled = true               # promote replica if primary dies
#        multi_az_enabled           = true               # replica in another AZ
#        at_rest_encryption_enabled = true
#        transit_encryption_enabled = true               # TLS in flight
#        auth_token                 = var.redis_auth_token  # required when transit encryption is on
#        snapshot_retention_limit   = 5                   # daily backups kept 5 days
#        apply_immediately          = true               # lab convenience
#
# Note: automatic_failover_enabled + multi_az_enabled REQUIRE num_cache_clusters >= 2.
# This whole thing bills (~cents/hr) — from your AWS credit. Destroy after.



resource "aws_security_group" "redis" {
  name        = "redis-sg"
  description = "Allows Redis access only from the client SG"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "redis-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis" {
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.redis.id
  from_port                    = 6379
  to_port                      = 6379
  description                  = "Redis access from app tier"
  referenced_security_group_id = aws_security_group.client.id
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "redis-lab"
  description                = "Lab Redis HA replication group"
  engine                     = "redis"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 2
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.redis.id]
  automatic_failover_enabled = true
  multi_az_enabled           = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token
  snapshot_retention_limit   = 5
  apply_immediately          = true
}
