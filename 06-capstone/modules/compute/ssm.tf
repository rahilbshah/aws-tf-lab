# SSM (Option B) — give the app instances an instance profile so you can reach them
# via Systems Manager (no bastion, no public IP, no SSH). Same instance-profile
# pattern as notes/02-ec2, with the AWS-managed SSM policy.
#
# Build:
#   - data.aws_iam_policy_document.ssm_assume   trust policy: principal Service
#        ec2.amazonaws.com, action sts:AssumeRole
#   - aws_iam_role.ssm                          assume_role_policy = that doc
#   - aws_iam_role_policy_attachment.ssm        role = the role,
#        policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   - aws_iam_instance_profile.ssm              role = aws_iam_role.ssm.name
#
# THEN add ONE line to aws_launch_template.this (in main.tf):
#   iam_instance_profile { name = aws_iam_instance_profile.ssm.name }
#   (note: on the launch template it's a BLOCK with `name =`, not a bare string)
#
# After apply, the launch template has a new version but EXISTING instances don't
# have the profile yet. Roll them so new ones pick it up:
#   aws autoscaling start-instance-refresh --auto-scaling-group-name app-asg
#   (or just terminate the 2 instances; the ASG relaunches them with the profile)
#
# Verify + connect (no bastion):
#   1. aws ssm describe-instance-information \
#        --query 'InstanceInformationList[].InstanceId' --output text
#      (the app instance IDs should appear once the agent registers ~2 min)
#   2. aws ssm start-session --target <app-instance-id> \
#        --document-name AWS-StartPortForwardingSessionToRemoteHost \
#        --parameters '{"host":["<RDS endpoint, no :5432>"],"portNumber":["5432"],"localPortNumber":["5432"]}'
#   3. TablePlus: plain PostgreSQL (NO "Over SSH"), host = 127.0.0.1, port 5432,
#      user dbadmin, tfvars password, database postgres.
#
# If an instance never shows in describe-instance-information, the SSM agent may
# not be running on the golden AMI — install via user_data: `snap install amazon-ssm-agent`.


data "aws_iam_policy_document" "ssm_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm" {
  name               = "ssm"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "ssm_profile"
  role = aws_iam_role.ssm.name
}
