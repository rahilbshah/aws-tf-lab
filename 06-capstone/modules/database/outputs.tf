# OUTPUTS the database module returns.

output "db_endpoint" {
  description = "RDS connection endpoint (host:port) — the app would use this"
  value       = aws_db_instance.this.endpoint # TODO: aws_db_instance.<name>.endpoint
}

output "db_sg_id" {
  description = "The DB security group ID"
  value       = aws_security_group.db.id # TODO: aws_security_group.<db>.id
}
