output "cloudfront_url" {
  description = "The distribution. This should work."
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "direct_s3_url" {
  description = "The origin, bypassing CloudFront. This should return 403 — that's OAC working."
  value       = "https://${aws_s3_bucket.origin.bucket_regional_domain_name}/index.html"
}

output "distribution_id" {
  description = "Needed for `aws cloudfront create-invalidation`."
  value       = aws_cloudfront_distribution.this.id
}

output "origin_bucket" {
  value = aws_s3_bucket.origin.id
}
