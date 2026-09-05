# Outputs — you need these for every aws sns publish / aws sqs receive-message.
#
#   9.  output "topic_arn"     – for `aws sns publish --topic-arn`
#  10.  output "queue_urls"    – a map of name -> queue URL; receive-message and
#                                get-queue-attributes both take the URL, not the ARN
#  11.  output "dlq_url"       – so you can watch a message land in it
#
# Note the recurring arn-vs-url split: subscriptions take the queue ARN, CLI
# commands take the queue URL. Both are attributes on aws_sqs_queue.
