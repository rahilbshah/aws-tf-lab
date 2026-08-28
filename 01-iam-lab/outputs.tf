output "instance_profile_name" {
  description = "Attach this to an EC2 instance or launch template — instances take a profile, not a role."
  value       = aws_iam_instance_profile.s3_reader.name
}

output "bucket_name" {
  description = "The lab bucket. Try listing it with and without the allowed prefix."
  value       = aws_s3_bucket.this.id
}

output "policy_arn" {
  description = "The plan cannot render this policy. Read it after apply with: aws iam get-policy-version --policy-arn <this> --version-id v1"
  value       = aws_iam_policy.reports_read.arn
}
