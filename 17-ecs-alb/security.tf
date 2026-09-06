# ==========================================================================
# Security groups. Write these before the ALB - both the ALB and the service
# reference them.
#
# This is the part you reasoned about correctly in the orient: the reason the
# internet cannot reach your tasks is THIS FILE, not the subnet choice. The
# private subnet is defence in depth. The security group is the access control.
# ==========================================================================

# TODO(10) aws_security_group.alb
#          vpc_id      = the VPC
#          ingress     : TCP 80 from 0.0.0.0/0   (this one really is public)
#          egress      : all, to anywhere
#          Deliberately open on 80 - it is a public web entry point. That is
#          the ONE security group in this lab allowed to see 0.0.0.0/0.

# TODO(11) aws_security_group.tasks
#          vpc_id      = the VPC
#          ingress     : TCP var.container_port, and for the source use
#                        `security_groups = [aws_security_group.alb.id]`
#                        NOT a CIDR. Referencing the ALB's SG means "whatever
#                        IPs the ALB happens to have, now and after it scales".
#                        A CIDR would be wrong the moment the ALB adds a node.
#          egress      : all, to anywhere. It needs this to reach Docker Hub
#                        through the NAT gateway. Lock egress down and the
#                        image pull fails.
#
#   Note the shape: two security groups, one referencing the other, no CIDRs
#   between them. That is the pattern the exam calls "security group chaining"
#   and it is the same one you used for ALB -> ASG in 04-alb-asg.
