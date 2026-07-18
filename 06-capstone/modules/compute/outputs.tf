# OUTPUTS the compute module returns.
# - alb_dns_name: the URL to hit the app (root surfaces this to you)
# - app_sg_id: the app-tier security group — the DATABASE module needs this so
#   RDS can allow ONLY the app tier (SG-to-SG, the pattern from 04-alb-asg).

output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = aws_lb.this.dns_name # TODO: aws_lb.<name>.dns_name
}

output "app_sg_id" {
  description = "Security group ID of the app tier (for the DB to allow)"
  value       = aws_security_group.app.id # TODO: aws_security_group.<app>.id
}
