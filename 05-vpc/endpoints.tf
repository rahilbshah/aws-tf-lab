# 05.3 – VPC Endpoints: S3 Gateway endpoint (FREE)
#
# A gateway endpoint lets instances in your PRIVATE subnets reach S3 over the
# AWS backbone with NO internet path (no NAT needed just for S3). It works by
# adding an S3 prefix-list route to the route tables you attach it to.
#
#   aws_vpc_endpoint.s3
#     - vpc_id            = aws_vpc.this.id
#     - service_name      = "com.amazonaws.us-east-1.s3"   (region-specific format:
#                            com.amazonaws.<region>.<service>; or look it up with
#                            data.aws_vpc_endpoint_service to avoid hardcoding region)
#     - vpc_endpoint_type = "Gateway"
#     - route_table_ids   = [aws_route_table.private.id]   <-- THIS is the magic:
#                            it injects a route to S3's prefix list into the private RT
#     - tags Name = "s3-gateway-endpoint"
#     - (optional) policy = <JSON> to restrict which buckets/actions; default = full access
#
# After apply, look at the private route table in the console: you'll see a new
# route "pl-xxxx (S3) -> vpce-xxxx". That's private instances reaching S3 with
# zero NAT/IGW involvement. Gateway endpoints = S3 + DynamoDB ONLY, and FREE.
#
# (Interface endpoint / PrivateLink — for any OTHER service — would be:
#    vpc_endpoint_type = "Interface", subnet_ids = [...], security_group_ids = [...],
#    private_dns_enabled = true.  Costs ~$0.01/hr per AZ — conceptual, not building it.)

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    "Name" = "s3-gateway-endpoint"
  }
}


