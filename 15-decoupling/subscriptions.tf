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
