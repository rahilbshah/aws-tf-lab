# TODO(49) outputs — add each as its phase arrives:
#   ecr_repository_url    (phase 2 — you need it for docker push)
#   alb_url               (phase 3)
#   db_secret_arn         (phase 4 — aws_db_instance.this.master_user_secret[0].secret_arn,
#                          so you can `aws secretsmanager get-secret-value` and SEE the password
#                          RDS made, and confirm it is nowhere in your files)
#   uploads_bucket        (phase 5)
#   cloudfront_url        (phase 6 — "https://${aws_cloudfront_distribution.this.domain_name}")

output "ecr_repository_url" {
  description = "ECR repository URL — use this as the target for `docker push`"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_url" {
  description = "ALB DNS name — curl this to hit the app"
  value       = "http://${aws_lb.this.dns_name}"
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the RDS master password — `aws secretsmanager get-secret-value --secret-id <this>` to see it"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "uploads_bucket" {
  description = "S3 bucket name for uploads — `aws s3 ls s3://<this>/uploads/` to see objects"
  value       = aws_s3_bucket.uploads.id
}

output "cloudfront_url" {
  description = "CloudFront URL — the only way in now that the ALB is locked down"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}
