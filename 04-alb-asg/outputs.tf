# Outputs go here. The one you'll definitely want:
#
#   output "alb_dns_name" { value = aws_lb.this.dns_name }
#
# After apply, `terraform output alb_dns_name` gives you the URL to paste in a
# browser. Refresh a few times and watch the served instance-id change as the
# ALB spreads requests across AZs.

output "alb_dns_name" {
  description = "Public DNS name of the ALB — paste into a browser to test"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "Useful for checking target health via CLI without digging through the console"
  value       = aws_lb_target_group.this.arn
}

output "asg_name" {
  description = "Useful for `aws autoscaling describe-auto-scaling-instances` while testing"
  value       = aws_autoscaling_group.this.name
}