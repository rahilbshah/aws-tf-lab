output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ) — where an ALB / bastion would live"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (one per AZ) — where app/ASG instances would live"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

# Added after the NAT peek (nat.tf) — confirms private-subnet egress IP:
# output "nat_public_ip" {
#   description = "Public IP of the NAT gateway; private-subnet outbound traffic appears from here"
#   value       = aws_eip.nat.public_ip
# }
