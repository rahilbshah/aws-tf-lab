# Endpoints to verify after apply (an app in the client SG would use these).
#
#   output "rds_endpoint" {
#     value = aws_db_instance.this.endpoint
#   }
#   output "redis_primary_endpoint" {
#     value = aws_elasticache_replication_group.this.primary_endpoint_address
#   }
#   output "redis_reader_endpoint" {
#     value = aws_elasticache_replication_group.this.reader_endpoint_address
#   }
#
# Notice Redis (like Aurora) gives you a PRIMARY endpoint (writes) and a READER
# endpoint (load-balanced reads) — the same writer/reader split from 07-rds-aurora.

output "rds_endpoint" {
  value = aws_db_instance.this.endpoint
}
output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}
output "redis_reader_endpoint" {
  value = aws_elasticache_replication_group.this.reader_endpoint_address
}
