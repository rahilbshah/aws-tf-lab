# ==========================================================================
# ECS itself. Write this LAST. It references the target group, both security
# groups, the private subnets, the log group and the execution role.
# ==========================================================================

# TODO(17) aws_cloudwatch_log_group.this
#          name              = "/ecs/${var.name}"
#          retention_in_days = var.log_retention_days
#          Create it explicitly. If you let the awslogs driver create it
#          implicitly, terraform destroy leaves it behind and you pay storage
#          on a lab you thought was gone.

# TODO(18) aws_ecs_cluster.this
#          name = var.name
#          That is genuinely all. A cluster is a logical grouping - with
#          Fargate there is no capacity to attach, which is why this resource
#          looks suspiciously empty compared to what you saw in the video.

# TODO(19) aws_ecs_task_definition.hello
#          family                   = var.name
#          requires_compatibilities = ["FARGATE"]
#          network_mode             = "awsvpc"     <- mandatory for Fargate
#          cpu                      = var.task_cpu
#          memory                   = var.task_memory
#          execution_role_arn       = the role from (15)
#          container_definitions    = jsonencode([{ ... }])
#
#          The container_definitions object needs, at minimum:
#            name         = "hello"        <- remember this string for (20)
#            image        = var.container_image
#            essential    = true
#            portMappings = [{ containerPort = var.container_port }]
#            logConfiguration = {
#              logDriver = "awslogs"
#              options   = { awslogs-group, awslogs-region, awslogs-stream-prefix }
#            }
#          Note the keys are camelCase - this JSON is the ECS API's shape, not
#          Terraform's. Mixing in snake_case here is a common first-try error.
#
#          CPU/MEMORY ARE NOT FREE-FORM. With cpu = "256" the only valid
#          memory values are 512, 1024 and 2048. An invalid pair fails at
#          apply with a ClientException, not at plan.
#
#          Remember the AMI analogy: this is a blueprint, and every change
#          registers a NEW REVISION rather than mutating the old one. Change
#          the image tag, apply, and watch the plan say the service moves from
#          :1 to :2. That is your deployment mechanism.

# TODO(20) aws_ecs_service.hello
#          name            = var.name
#          cluster         = the cluster from (18)
#          task_definition = the task definition from (19)
#          desired_count   = var.desired_count
#          launch_type     = "FARGATE"
#
#          network_configuration {
#            subnets          = the two PRIVATE subnets from (4)
#            security_groups  = [the tasks SG from (11)]
#            assign_public_ip = false      # they egress via the NAT gateway
#          }
#
#          load_balancer {
#            target_group_arn = (13)
#            container_name   = "hello"    # must match the name in (19) EXACTLY
#            container_port   = var.container_port
#          }
#
#          depends_on = [aws_lb_listener.http]
#          ^ genuinely needed. Terraform sees no dependency between the service
#          and the listener, so it may create the service first, and ECS
#          rejects it with "The target group does not have an associated load
#          balancer." This is the single most common failure in this lab.
#
#          DESIGN CHOICE, flagged: you could add a `deployment_circuit_breaker`
#          block with rollback = true. Production always wants it. Skip it on
#          the first apply so you SEE a bad deploy fail, then add it and watch
#          it roll back - that contrast is worth more than having it from the
#          start.
