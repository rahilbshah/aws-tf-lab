# ==========================================================================
# The load balancer. Write this after security.tf, before ecs.tf - the ECS
# service references the target group, and the service will fail to create if
# the listener does not exist yet.
#
# COST: ALB bills $0.0225/hr the moment it exists, with zero traffic and zero
# healthy targets. It is the second most expensive thing here.
# ==========================================================================

# TODO(12) aws_lb.this
#          name               = var.name
#          internal           = false
#          load_balancer_type = "application"
#          security_groups    = [the ALB SG from (10)]
#          subnets            = the two PUBLIC subnets from (3)

# TODO(13) aws_lb_target_group.this
#          name        = var.name
#          port        = var.container_port
#          protocol    = "HTTP"
#          vpc_id      = the VPC
#          target_type = "ip"        <- THE line that matters in this lab
#
#          Why "ip": with awsvpc networking every Fargate task gets its own
#          ENI and private IP. There is no instance ID you own to register -
#          AWS runs the container on infrastructure you never see. The docs
#          define the two types as: `instance` = "targets are specified by
#          instance ID", `ip` = "targets are IP addresses".
#          Leave it at the default ("instance") and terraform apply SUCCEEDS,
#          the service creates, and no target ever registers. You will be
#          staring at a healthy-looking plan and a 503 from the ALB.
#
#          health_check { path = "/" } - nginxdemos/hello answers 200 on /.
#          Consider a shorter interval/healthy_threshold so you are not
#          waiting two minutes to see the thing come up.

# TODO(14) aws_lb_listener.http
#          load_balancer_arn = the ALB
#          port = 80, protocol = "HTTP"
#          default_action { type = "forward", target_group_arn = (13) }
#
#          HTTP only, no ACM certificate - you do not own a domain. That is
#          the deliberate production gap here; the 18- project closes it with
#          CloudFront's free *.cloudfront.net certificate in front.
