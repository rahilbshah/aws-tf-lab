output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.site.website_endpoint
}
output "website_domain" {
  value = aws_s3_bucket_website_configuration.site.website_domain
}
