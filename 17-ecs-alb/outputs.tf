# TODO(21) output "alb_url"
#          value = "http://${aws_lb.this.dns_name}"
#          The only output you actually need. Paste it in a browser.
#
# ==========================================================================
# WHAT TO LOOK AT, once it is up
#
# 1. Open the URL and hard-refresh several times. The page prints "Server
#    name", "Server address" and "Server hostname". The ADDRESS changes
#    between two private IPs - those are your two task ENIs. That is the load
#    balancer distributing, visible, which is why this image was chosen.
#
#    Faster from the terminal:
#      for i in $(seq 12); do curl -s $URL | grep -i 'Server address'; done
#
# 2. Console -> EC2 -> Target Groups -> your group -> Targets tab.
#    The registered targets are IP ADDRESSES, not instance IDs. Sit with that
#    for a second - it is the thing target_type = "ip" bought you.
#
# 3. ECS -> your service -> Tasks. Stop one task by hand. Watch the service
#    notice and start a replacement without you asking. That is the desired
#    state reconciliation loop you described in the orient, happening in front
#    of you. Watch the ALB target count drop to 1 and come back to 2.
#
# 4. CloudWatch -> Log groups -> /ecs/<name>. One log stream per task. This is
#    what the execution role bought you.
#
# THEN DESTROY IT. The NAT gateway and ALB bill by the hour whether you are
# looking at them or not.
# ==========================================================================
