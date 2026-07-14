# 05.2 – VPC Security: Flow Logs -> CloudWatch Logs
#
# Flow logs record connection METADATA (src/dst IP+port, protocol, bytes,
# ACCEPT/REJECT) — never the packet payload. Publishing to CloudWatch needs a
# log group + an IAM SERVICE ROLE (a callback to notes/01-iam: trust policy for
# a service principal). This is all free at this tiny scale.
#
#   C. aws_cloudwatch_log_group.flow      – name = "/vpc/flow-logs/vpc-05"
#                                            (retention_in_days = 7 to keep it tidy/cheap)
#
#   D. The IAM service role the flow-log service assumes to write logs:
#        - data.aws_iam_policy_document.flow_assume  – trust policy:
#              principal type "Service", identifiers ["vpc-flow-logs.amazonaws.com"],
#              action "sts:AssumeRole"
#        - aws_iam_role.flow_logs  – assume_role_policy = that document
#        - a permissions policy (inline aws_iam_role_policy OR a managed one) allowing:
#              logs:CreateLogStream, logs:PutLogEvents, logs:CreateLogGroup,
#              logs:DescribeLogStreams  on the log group
#
#   E. aws_flow_log.vpc
#        - vpc_id              = aws_vpc.this.id      (level: VPC. Could be subnet_id / eni_id)
#        - traffic_type        = "ALL"                (or ACCEPT / REJECT)
#        - log_destination_type = "cloud-watch-logs"
#        - log_destination     = aws_cloudwatch_log_group.flow.arn
#        - iam_role_arn        = aws_iam_role.flow_logs.arn
#
# After apply + a few minutes of traffic, check the log group in CloudWatch:
# each record ends in ACCEPT or REJECT — that's your "is a SG/NACL blocking this?"
# troubleshooting signal. (S3 is the alternative destination; it needs a bucket +
# bucket policy instead of the IAM role — CloudWatch is the classic, so we use it.)


resource "aws_cloudwatch_log_group" "flow" {
  name              = "/vpc/flow-logs/vpc-05"
  retention_in_days = 7
}

data "aws_iam_policy_document" "flow_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "flow_logs"
  assume_role_policy = data.aws_iam_policy_document.flow_assume.json
}

data "aws_iam_policy_document" "flow_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["${aws_cloudwatch_log_group.flow.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs_permissions" {
  name   = "flow-logs-permissions"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_permissions.json
}

resource "aws_flow_log" "vpc" {
  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow.arn
  iam_role_arn             = aws_iam_role.flow_logs.arn
  max_aggregation_interval = 60
}
