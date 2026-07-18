# COMPUTE MODULE — ALB + ASG + launch template + two security groups.
# Adapt your 04-alb-asg code, but: no provider block, drive from var.*, and use
# the subnet IDs passed IN (var.public_subnet_ids / var.app_subnet_ids) instead
# of data-source lookups. Golden AMI is still looked up here.
#
# Build:
#   - data.aws_ami.golden           (owners=["self"], tag:BakedBy=packer, most_recent)
#
#   SECURITY GROUPS (the tier chain — this is the whole point of 3-tier):
#   - aws_security_group.alb        in var.vpc_id
#       ingress 80 from 0.0.0.0/0 (public web), egress all
#   - aws_security_group.app        in var.vpc_id
#       ingress var.app_port FROM the alb SG (referenced_security_group_id),
#       egress all. (The DB SG will later allow FROM this app SG.)
#
#   LAUNCH TEMPLATE:
#   - aws_launch_template.this
#       image_id = data.aws_ami.golden.id, instance_type = var.instance_type,
#       vpc_security_group_ids = [app SG],
#       user_data = base64encode(file("${path.module}/user_data.sh"))
#       (path.module = THIS module's dir — that's why user_data.sh lives here)
#
#   ALB + TARGET GROUP + LISTENER:
#   - aws_lb.this                   internet-facing, subnets = var.public_subnet_ids, alb SG
#   - aws_lb_target_group.this      port 80 HTTP, vpc_id = var.vpc_id, health_check
#   - aws_lb_listener.http          port 80 -> forward to target group
#
#   AUTO SCALING GROUP:
#   - aws_autoscaling_group.this
#       vpc_zone_identifier = var.app_subnet_ids   (instances in PRIVATE subnets now!)
#       target_group_arns   = [target group],
#       health_check_type   = "ELB", grace period ~300 (apt install at boot),
#       min/max/desired = 2/4/2, launch_template { version = "$Latest" }
#
# Then fill outputs.tf: alb_dns_name + app_sg_id.
#
# Note: instances are in PRIVATE subnets now (not public like 04-alb-asg). They
# reach the internet for `apt install nginx` via the vpc module's NAT gateway.
# Only the ALB is public. That's the real production shape.

data "aws_ami" "golden" {
  owners      = ["self"]
  most_recent = true
  filter {
    name   = "tag:BakedBy"
    values = ["packer"]
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "ALB tier: allows HTTP (80) from the internet"
  vpc_id      = var.vpc_id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.alb.id

  tags = {
    Name = "alb-http-from-internet"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all protocols -> must NOT set from_port/to_port
  security_group_id = aws_security_group.alb.id

  tags = {
    Name = "alb-all-egress"
  }
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "App tier: allows traffic only from the ALB security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "app-http-from-alb"
  }
}

resource "aws_vpc_security_group_egress_rule" "app" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all protocols -> must NOT set from_port/to_port
  security_group_id = aws_security_group.app.id

  tags = {
    Name = "app-all-egress"
  }
}


resource "aws_launch_template" "this" {
  name_prefix            = "asg-lt-"
  image_id               = data.aws_ami.golden.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = base64encode(file("${path.module}/user_data.sh"))
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm.name
  }

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
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = "app-alb"
  }
}


resource "aws_lb_target_group" "this" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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
  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [aws_lb_target_group.this.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

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
