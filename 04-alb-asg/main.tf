# 04 – ALB + Auto Scaling Group (Scope A: core working stack)
#
# You write the resources. Suggested order (each references things above it,
# so top-to-bottom keeps the dependency graph natural):
#
#   DATA LOOKUPS
#   1. data.aws_vpc.default            – default VPC
#   2. data.aws_subnets.default        – its subnets (ALB + ASG need 2+ AZs)
#   3. data.aws_ami.golden             – YOUR baked image: filter owners=["self"]
#                                        + tag:BakedBy = "packer", most_recent = true
#
#   SECURITY GROUPS  (two of them — this is the whole point of an LB)
#   4. aws_security_group.alb          – ingress 80 from 0.0.0.0/0 (public web is fine HERE)
#   5. aws_security_group.instance     – ingress 80 FROM the ALB SG only
#                                        (reference the ALB SG as the source, NOT a CIDR)
#      + egress on both (all outbound) so instances can apt-install nginx at boot
#
#   LAUNCH TEMPLATE  (the blueprint the ASG stamps out — replaces legacy launch_configuration)
#   6. aws_launch_template.this        – image_id, instance_type, vpc_security_group_ids
#                                        = [instance SG], user_data = base64encode(file/templatefile),
#                                        (optional key_name / iam_instance_profile)
#
#   LOAD BALANCER + TARGET GROUP + LISTENER
#   7. aws_lb.this                     – load_balancer_type = "application", subnets (2+ AZ), security_groups = [alb SG]
#   8. aws_lb_target_group.this        – port 80, protocol HTTP, vpc_id, health_check { path = "/" ... }
#   9. aws_lb_listener.http            – port 80, default_action forward -> target group
#
#   AUTO SCALING GROUP
#  10. aws_autoscaling_group.this      – min/max/desired, vpc_zone_identifier = subnet ids,
#                                        launch_template { ... }, target_group_arns = [tg arn],
#                                        health_check_type = "ELB", health_check_grace_period = 120
#
# Reminders baked in from earlier topics:
#   - user_data is in ./user_data.sh (already written for you — it installs nginx and
#     shows the instance id via IMDSv2). Wire it in with user_data = base64encode(file("${path.module}/user_data.sh"))
#   - the ASG auto-registers instances into the target group via target_group_arns —
#     do NOT create aws_autoscaling_attachment or register targets by hand.
#   - health_check_type = "ELB" is what makes a failed ALB health check actually
#     trigger replacement. Default "EC2" would leave a zombie serving 500s.

data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b"]
  }
}

data "aws_ami" "golden" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Project"
    values = ["saa-c03-learning"]
  }

  filter {
    name   = "tag:BakedBy"
    values = ["packer"]
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP from the internet"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = var.app_port
  to_port           = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "alb_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "instance" {
  name        = "instance-sg"
  description = "Allow HTTP only from the ALB"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "instance-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_sg_ipv4" {
  security_group_id            = aws_security_group.instance.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "instance_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "this" {
  name_prefix            = "asg-lt-"
  image_id               = data.aws_ami.golden.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data              = base64encode(file("${path.module}/user_data.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "asg-instance"
    }
  }

  tags = {
    Name = "asg-launch-template"
  }

}

resource "aws_lb" "this" {
  name               = "app-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = "app-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "app-tg"
  }

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_autoscaling_group" "this" {
  name             = "app-asg"
  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.this.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}