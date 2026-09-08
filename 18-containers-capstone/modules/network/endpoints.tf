# ==========================================================================
# VPC endpoints. Only the free one, for now.
# ==========================================================================

# TODO(13) aws_vpc_endpoint.s3
#          vpc_id            = the VPC
#          service_name      = "com.amazonaws.<region>.s3"
#                              build it from data.aws_region.current.region
#                              (NOTE: `.name` is DEPRECATED on provider v6 -
#                              this bit us in 17-ecs-alb. Use `.region`.)
#          vpc_endpoint_type = "Gateway"
#          route_table_ids   = the PRIVATE and ISOLATED route tables
#
#          A gateway endpoint is FREE - no hourly charge, no per-GB charge.
#          It works by adding a prefix-list route to the route tables you name,
#          which is why it takes route_table_ids and an interface endpoint
#          takes subnet_ids. That difference is exam-testable.
#
#          Two things this buys you:
#            1. S3 traffic from private subnets skips the NAT gateway, so you
#               stop paying $0.045/GB to process it. On an app that writes
#               uploads to S3 this is the single biggest NAT saving available.
#            2. The isolated tier gets S3 access WITHOUT any internet route -
#               which is how RDS backups and, later, ECR image layers work in
#               a subnet that cannot reach the internet.
#
#          NOT YET (phase 3, when we introduce ECR): the interface endpoints
#          for ecr.api, ecr.dkr and logs. Those bill per ENI per AZ and three
#          of them cost more than one NAT gateway - so we add them only if we
#          decide to drop NAT entirely. Do the arithmetic then, not now.

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [for rt in aws_route_table.private : rt.id],
    [aws_route_table.isolated.id]
  )

  tags = {
    Name = "${var.name}-s3-endpoint"
  }

}
