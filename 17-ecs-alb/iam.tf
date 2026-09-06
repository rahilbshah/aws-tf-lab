# ==========================================================================
# The task execution role. You said in the orient that a public image needs
# no IAM - correct, and that is the part most people get wrong. Nothing in
# AWS authenticates you to Docker Hub.
#
# This role is not for the pull. It is for the LOGS. AWS lists "sends
# container logs to CloudWatch Logs using the awslogs log driver" as a case
# where the execution role is required, and you want logs, because without
# them a task that dies on startup dies silently.
#
# Hold the distinction: this role belongs to the FARGATE AGENT (pull image,
# ship logs). A separate task role would belong to YOUR CONTAINER (call S3,
# read DynamoDB). nginxdemos/hello calls no AWS API, so this lab has no task
# role at all. The 18- project will have both, and that is where the
# difference gets tested.
# ==========================================================================

# TODO(15) aws_iam_role.task_execution
#          assume_role_policy trusting service "ecs-tasks.amazonaws.com"
#          Use a data "aws_iam_policy_document" for the trust policy the way
#          you did in 01-iam-lab, not a raw jsonencode - you already know the
#          pattern and it reads better in a review.

# TODO(16) aws_iam_role_policy_attachment.task_execution
#          role       = (15)
#          policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
#
#          AWS-managed policy. Note the `service-role/` path in the ARN -
#          get that wrong and you get a "policy does not exist" at apply.
