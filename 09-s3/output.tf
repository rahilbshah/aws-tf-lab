output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}
output "website_domain" {
  value = aws_s3_bucket_website_configuration.site.website_domain
}

output "source_bucket" {
  description = "Source bucket — upload here to trigger events / replication"
  value       = aws_s3_bucket.this.id
}

output "queue_url" {
  description = "SQS queue receiving S3 events (read it with sqs receive-message)"
  value       = aws_sqs_queue.events.id
}

output "dest_bucket" {
  description = "Replication destination bucket (us-west-2)"
  value       = aws_s3_bucket.dest.id
}
