# ==========================================================================
# PHASE 3a — the load balancer. Identical in shape to 17-ecs-alb.
# COST: $0.0225/hr + LCUs from the moment it exists.
# ==========================================================================

# TODO(22) aws_lb.this
#          internal = false, load_balancer_type = "application",
#          security_groups = [ALB SG], subnets = [public_a, public_b]

# TODO(23) aws_lb_target_group.app
#          port = var.container_port, protocol = "HTTP", vpc_id,
#          target_type = "ip"                 <- Fargate, as before
#          deregistration_delay = 30          <- remember the 5-minute drain from 17-
#          health_check { path = "/health", interval = 10, healthy_threshold = 2, matcher = "200" }
#
#          /health, not /. The app's /health has NO dependencies, so a task
#          stays "healthy" to the ALB even while RDS is unreachable. That is the
#          correct design: the health check answers "can this task serve
#          requests at all", not "is every downstream up".

# TODO(24) aws_lb_listener.http
#          port 80, HTTP, default_action forward -> the target group
#          HTTP only. CloudFront provides HTTPS to the user in phase 6; the
#          CloudFront -> ALB leg stays HTTP inside AWS's network.
