# OUTPUTS the vpc module returns (the root reads these to wire other modules).
# This is the module's "return value" — expose exactly what callers need,
# nothing more. Fill the values once you've written the resources in main.tf.

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "app_subnet_ids" {
  description = "IDs of the app-tier private subnets"
  value       = [aws_subnet.app_a.id, aws_subnet.app_b.id]
}

output "data_subnet_ids" {
  description = "IDs of the data-tier private subnets"
  value       = [aws_subnet.data_a.id, aws_subnet.data_b.id]
}
