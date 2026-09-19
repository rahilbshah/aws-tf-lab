# ==========================================================================
# PHASE 7 — the task count follows CPU. And the one NEW Terraform idea in this
# whole project, taught here because this is where you cannot avoid it.
# COST: nothing.
# ==========================================================================

# TODO(46) aws_appautoscaling_target.ecs
#          service_namespace  = "ecs"
#          resource_id        = "service/${cluster name}/${service name}"
#          scalable_dimension = "ecs:service:DesiredCount"
#          min_capacity = var.autoscale_min, max_capacity = var.autoscale_max

# TODO(47) aws_appautoscaling_policy.cpu
#          policy_type = "TargetTrackingScaling", attached to (46) via its
#          resource_id / scalable_dimension / service_namespace,
#          target_tracking_scaling_policy_configuration {
#            target_value = var.autoscale_cpu_target
#            predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
#            scale_in_cooldown = 60, scale_out_cooldown = 60
#          }
#
#          This is APPLICATION Auto Scaling, not EC2 Auto Scaling. Different
#          service, different resources, and there is no ASG anywhere here
#          because Fargate has no instances to scale. The exam asks about both;
#          keep them separate in your head.

# ---- the new Terraform idea ----------------------------------------------------
# TODO(48) Add to aws_ecs_service.app (TODO 30):
#            lifecycle {
#              ignore_changes = [desired_count]
#            }
#
#          Why: you saw this in 17-ecs-alb. You scaled to 5 in the console, and
#          the next plan wanted to drag it back to 2. Now the AUTOSCALER changes
#          desired_count on purpose - and without this block, every
#          terraform apply would fight it back to var.desired_count.
#
#          ignore_changes says: "I set this initially; something else owns it
#          afterwards." Terraform still creates the service with desired_count =
#          2; it just stops caring what the number is later.
#
#          That is the entire feature. One argument. It is not "advanced
#          Terraform", it is a sentence about who owns a value.
#
# PHASE 7 IS DONE when:  you generate load —
#            for i in $(seq 2000); do curl -s https://<dist>.cloudfront.net/db >/dev/null & done; wait
#          — and watch ECS -> service -> Tasks grow past 2 over a few minutes,
#          then shrink back after the cooldown. And terraform plan says "No
#          changes" the whole time, because of TODO 48.

resource "aws_appautoscaling_target" "ecs" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.autoscale_min
  max_capacity       = var.autoscale_max
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name}-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = var.autoscale_cpu_target
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
