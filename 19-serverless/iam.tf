# ==========================================================================
# The Lambda execution role.
#
# Carry across what you learned in 17-containers: in ECS you had an EXECUTION
# role (the agent: pull image, ship logs) and a TASK role (your code: call
# AWS). Lambda collapses both jobs into ONE role - the execution role - and
# that is a genuine difference worth holding, because the exam asks about
# both services and the naming does not match.
#
#   ECS execution role  ~  the plumbing
#   ECS task role       ~  your code's permissions
#   Lambda execution role = BOTH of those at once
# ==========================================================================

# TODO(3) aws_iam_role.lambda
#         assume_role_policy trusting service "lambda.amazonaws.com"
#         Use data "aws_iam_policy_document" like you did in 01-iam-lab and
#         17-ecs-alb. Note the principal is lambda.amazonaws.com, NOT
#         ecs-tasks.amazonaws.com - every service has its own.

# TODO(4) aws_iam_role_policy_attachment.lambda_basic
#         policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#
#         This AWS-managed policy grants ONLY CloudWatch Logs permissions
#         (CreateLogGroup, CreateLogStream, PutLogEvents). It is the Lambda
#         equivalent of the logging half of AmazonECSTaskExecutionRolePolicy.
#         Without it your function runs and you see nothing.
#
#         NOTE there is a second managed policy, AWSLambdaVPCAccessExecutionRole,
#         which adds the EC2 network-interface permissions for Hyperplane ENIs.
#         You do NOT need it - this function talks to DynamoDB over the public
#         AWS API and has no reason to be in a VPC. Putting it in one would
#         cost you internet access and buy nothing.

# TODO(5) aws_iam_role_policy.lambda_dynamodb  (an INLINE policy)
#         Allow exactly: dynamodb:PutItem, dynamodb:GetItem, dynamodb:Query
#         Resource: the table's ARN from (1) — NOT "*"
#
#         This is the least-privilege exercise. The handler does three things,
#         so grant three actions. It never scans, never deletes, never touches
#         another table. If you find yourself typing "dynamodb:*" or "*", stop
#         and ask which of the three calls in handler.py needs it.
#
#         DESIGN CHOICE: inline policy (aws_iam_role_policy) vs a standalone
#         managed policy (aws_iam_policy + attachment). Inline is right when
#         the permissions are meaningless outside this one role, which is the
#         case here. Reach for a managed policy when several roles share it.
