# Outputs — you need these for every aws sns publish / aws sqs receive-message.
#
#   9.  output "topic_arn"     – for `aws sns publish --topic-arn`
#  10.  output "queue_urls"    – a map of name -> queue URL; receive-message and
#                                get-queue-attributes both take the URL, not the ARN
#  11.  output "dlq_url"       – so you can watch a message land in it
#
# Note the recurring arn-vs-url split: subscriptions take the queue ARN, CLI
# commands take the queue URL. Both are attributes on aws_sqs_queue.

output "topic_arn" {
  description = "SNS topic ARN — pass to `aws sns publish --topic-arn`"
  value       = aws_sns_topic.this.arn
}

output "queue_urls" {
  description = "Map of queue name -> URL — used by receive-message / get-queue-attributes"
  value = {
    a = aws_sqs_queue.a.id
    b = aws_sqs_queue.b.id
  }
}

output "dlq_url" {
  description = "Dead-letter queue URL — watch this to confirm redrive"
  value       = aws_sqs_queue.dlq.id
}
