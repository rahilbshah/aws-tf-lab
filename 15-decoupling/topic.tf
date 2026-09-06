# SNS topic — the fan-out point. Build this FIRST; everything else references it.
#
# Cost: SNS and SQS are both comfortably inside the always-free tier at lab
# volumes (first million requests/publishes per month). Nothing here bills by
# the hour. Destroy anyway at the end — a queue holding messages is state you
# will forget about.
#
#   1.  aws_sns_topic.this     – name = "${var.name_prefix}-events"
#
# A topic with no subscribers does not error and does not queue anything — it
# silently discards what you publish. Worth knowing before you wonder where
# your first test message went.

resource "aws_sns_topic" "this" {
  name = "${var.name_prefix}-events"
}
