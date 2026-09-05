###############################################################################
# Wiring SNS to SQS — the subscription, and the permission that makes it work
###############################################################################

# TODO(4): aws_sns_topic_subscription per queue, protocol = "sqs".
#          Watch which ARN goes in `endpoint` and which in `topic_arn` — this
#          is the .arn-vs-.name class of mistake from 01-iam, one level up.


# TODO(5): aws_sqs_queue_policy for each queue.  THIS IS THE LESSON.
#
#          A queue rejects everything by default, so SNS cannot deliver until
#          the queue's own resource policy allows it. Build the document with
#          data "aws_iam_policy_document" and grant sqs:SendMessage to the
#          service principal that does the delivering.
#
#          Then stop, because you have now seen this exact shape three times
#          (09-s3/events.tf, 01-iam-lab, 11-cloudfront):
#
#            - Which service principal delivers an SNS message?
#            - That principal is identical for every AWS customer on earth.
#              So what stops ANYONE's SNS topic writing into your queue?
#            - Which condition key pins it to YOUR topic, and which operator?
#
#          Get this wrong and everything still works. That is the whole point.
