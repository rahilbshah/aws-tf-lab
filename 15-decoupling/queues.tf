# The queues — one per downstream consumer, plus the dead-letter queue.
#
# Write the DLQ before queue A: A's redrive_policy needs the DLQ's ARN.
#
#   2.  aws_sqs_queue.dlq      – name = "${var.name_prefix}-dlq"
#                                message_retention_seconds = ?  (see below)
#
#   3.  aws_sqs_queue.a        – name = "${var.name_prefix}-a"
#                                visibility_timeout_seconds = var.visibility_timeout
#                                redrive_policy = jsonencode({
#                                    deadLetterTargetArn = <the DLQ's arn>
#                                    maxReceiveCount     = var.max_receive_count
#                                })
#
#   4.  aws_sqs_queue.b        – name = "${var.name_prefix}-b"
#                                visibility_timeout_seconds = var.visibility_timeout
#                                no DLQ on this one, so you can compare behaviour
#
# (3 and 4 differ only in name and the redrive policy — for_each over a map is
#  legitimate here, but two explicit resources is clearer while learning. Pick.)
#
# On the DLQ's retention: AWS documents that for STANDARD queues a message keeps
# its ORIGINAL enqueue timestamp when it moves to the DLQ. So a message that sat
# 3 days in queue A arrives in the DLQ already 3 days old. Given that, should the
# DLQ's retention be shorter than, equal to, or longer than queue A's? Answer it
# to yourself, then set the number.

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name_prefix}-dlq"
  message_retention_seconds = 518400 # longer then Queue A's so someone can review it before it gets deleted
}

resource "aws_sqs_queue" "a" {
  name                       = "${var.name_prefix}-a"
  visibility_timeout_seconds = var.visibility_timeout
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue" "b" {
  name                       = "${var.name_prefix}-b"
  visibility_timeout_seconds = var.visibility_timeout
}
