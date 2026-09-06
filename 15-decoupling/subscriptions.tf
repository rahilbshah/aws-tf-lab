# Wiring SNS to SQS — the subscription, and the permission that makes it work.
#
#   5.  aws_sns_topic_subscription.a / .b
#                                topic_arn = the topic's arn
#                                protocol  = "sqs"
#                                endpoint  = the QUEUE'S ARN  (not its URL —
#                                            the arn/url distinction here is the
#                                            same class of mistake as .arn vs
#                                            .name in 01-iam)
#
#   6.  data.aws_iam_policy_document.allow_sns   ← THE LESSON. Read below first.
#                                statement: effect "Allow", actions
#                                ["sqs:SendMessage"], resources = the queue arn,
#                                principals { type = "Service", identifiers = [?] }
#                                condition { test = ? , variable = ? , values = [?] }
#
#   7.  aws_sqs_queue_policy.a / .b
#                                queue_url = the queue's id
#                                policy    = the document's .json
#
# Why a policy is needed at all: a queue rejects everything by default. The
# subscription tells SNS where to deliver; it does not give SNS permission to.
# Without 6 and 7 the subscription exists, the publish succeeds, and the message
# silently never arrives.
#
# Now the part worth stopping on. You have written this exact shape three times
# already — 09-s3/events.tf, 01-iam-lab, 11-cloudfront:
#
#   - Which service principal delivers an SNS message into a queue?
#   - That principal is byte-identical for every AWS customer on earth. So with
#     only the principal and no condition, whose topics can write to your queue?
#   - Which condition key pins it to YOUR topic, and which operator does an ARN
#     comparison rather than a string one?
#
# Say the answer out loud before you write it. Get it wrong and every test you
# run still passes — that is precisely why it is worth getting right.

resource "aws_sns_topic_subscription" "a" {
  topic_arn            = aws_sns_topic.this.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.a.arn
  raw_message_delivery = true
}

resource "aws_sns_topic_subscription" "b" {
  topic_arn            = aws_sns_topic.this.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.b.arn
  raw_message_delivery = true
}

data "aws_iam_policy_document" "allow_sns" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.a.arn, aws_sqs_queue.b.arn]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.this.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "a" {
  queue_url = aws_sqs_queue.a.id
  policy    = data.aws_iam_policy_document.allow_sns.json
}

resource "aws_sqs_queue_policy" "b" {
  queue_url = aws_sqs_queue.b.id
  policy    = data.aws_iam_policy_document.allow_sns.json
}
