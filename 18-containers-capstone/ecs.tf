# ==========================================================================
# PHASE 3b — the cluster, the two roles, the task definition, the service.
#
# Same as 17-ecs-alb with THREE changes, each one a real lesson:
#   1. the image comes from YOUR ECR, not Docker Hub
#   2. there are now TWO roles - the execution role AND a task role
#   3. the task definition grows env vars and (in phase 4) secrets
# ==========================================================================

# TODO(25) aws_cloudwatch_log_group.app     name "/ecs/${var.name}", retention var.log_retention_days

# TODO(26) aws_ecs_cluster.this             name = var.name

# ---- the EXECUTION role: what the Fargate AGENT may do --------------------
# TODO(27) aws_iam_role.task_execution      trust ecs-tasks.amazonaws.com
#          + aws_iam_role_policy_attachment -> AmazonECSTaskExecutionRolePolicy
#          That managed policy covers: pull from ECR, write to CloudWatch Logs.
#          In phase 4 you ADD an inline policy to it for secretsmanager:GetSecretValue
#          on ONE secret ARN - because the agent is what fetches the secret and
#          injects it as an env var before your code starts.

# ---- the TASK role: what YOUR CODE may do ---------------------------------
# TODO(28) aws_iam_role.task                trust ecs-tasks.amazonaws.com (same trust, different job)
#          Starts EMPTY. In phase 5 you attach an inline policy: s3:PutObject on
#          the uploads bucket only. Nothing else, ever.
#
#   This is the ECS distinction the exam tests and 17-containers.md drills:
#     execution role = the plumbing (pull image, ship logs, fetch the secret)
#     task role      = your application's own AWS API calls
#   Your app code CANNOT read the DB secret - it never has secretsmanager
#   permission. It receives the password as an env var the agent set. That
#   separation is the point.

# TODO(29) aws_ecs_task_definition.app
#          family = var.name, requires_compatibilities ["FARGATE"], network_mode "awsvpc",
#          cpu/memory from vars, execution_role_arn = (27), task_role_arn = (28),
#          runtime_platform { cpu_architecture = "ARM64", operating_system_family = "LINUX" }
#            ^ must match the image you pushed. Mismatch = "exec format error" at runtime.
#
#          container_definitions = jsonencode([{
#            name = "app", image = "${ecr repository_url}:${var.image_tag}", essential = true,
#            portMappings = [{ containerPort = var.container_port }],
#            environment = [
#              { name = "IMAGE_TAG", value = var.image_tag },
#              # phase 4 adds: DB_HOST, DB_NAME, DB_USER, REDIS_HOST
#              # phase 5 adds: UPLOAD_BUCKET
#            ],
#            # phase 4 adds:
#            # secrets = [{ name = "DB_PASSWORD", valueFrom = "${secret arn}:password::" }]
#            logConfiguration = { logDriver = "awslogs", options = { awslogs-group, awslogs-region, awslogs-stream-prefix = "app" } }
#          }])
#
#          `environment` = plain values, visible to anyone who can DescribeTaskDefinition.
#          `secrets`     = fetched by the agent at start, never stored in the task def.
#          The DB password goes in `secrets`. Getting this wrong is the most
#          common real-world ECS security mistake, and it is a one-word difference.

# TODO(30) aws_ecs_service.app
#          cluster, task_definition, desired_count = var.desired_count, launch_type "FARGATE",
#          network_configuration { subnets = [private_a, private_b], security_groups = [app SG], assign_public_ip = false }
#          load_balancer { target_group_arn, container_name = "app", container_port = var.container_port }
#          deployment_circuit_breaker { enable = true, rollback = true }
#          depends_on = [aws_lb_listener.http]
#
#          (phase 7 adds a lifecycle block here - not yet)
#
# PHASE 3 IS DONE when:  curl http://<alb-dns>/         -> served_by alternates between two hostnames
#                        curl http://<alb-dns>/db       -> 503 "not configured yet", missing DB_HOST...
# That 503 is CORRECT at this phase. The app is telling you what phase 4 will add.

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
}

resource "aws_ecs_cluster" "this" {
  name = var.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_read_secret" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.this.master_user_secret[0].secret_arn]
  }
}


resource "aws_iam_role_policy" "execution_read_secret" {
  name   = "${var.name}-read-db-secret"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.execution_read_secret.json
}


resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "task_s3" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]
  }
}

resource "aws_iam_role_policy" "task_s3" {
  name   = "${var.name}-upload-s3"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_s3.json
}


data "aws_region" "current" {}

resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = var.container_port
    }]

    environment = [
      { name = "IMAGE_TAG", value = var.image_tag },
      { name = "DB_HOST", value = aws_db_instance.this.address },
      { name = "DB_NAME", value = var.db_name },
      { name = "DB_USER", value = var.db_username },
      { name = "REDIS_HOST", value = aws_elasticache_cluster.this.cache_nodes[0].address },
      { name = "UPLOAD_BUCKET", value = aws_s3_bucket.uploads.id },
    ]

    secrets = [{
      name      = "DB_PASSWORD"
      valueFrom = "${aws_db_instance.this.master_user_secret[0].secret_arn}:password::"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = "app"
      }
    }

  }])
}

resource "aws_ecs_service" "app" {
  name            = var.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.http]

  lifecycle {
    ignore_changes = [desired_count]
  }

}
