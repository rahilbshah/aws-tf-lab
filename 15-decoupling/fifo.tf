# Optional — a FIFO queue, for the ordering and deduplication demo.
# Skip this entirely if you would rather keep the lab small; nothing else
# depends on it.
#
#   8.  aws_sqs_queue.orders_fifo
#                                name = "${var.name_prefix}-orders.fifo"
#                                       ^ the ".fifo" suffix is REQUIRED; the
#                                         apply fails without it
#                                fifo_queue                  = true
#                                content_based_deduplication = true
#
# content_based_deduplication makes SQS hash the message BODY (SHA-256, body
# only — not attributes) to build the deduplication ID for you. That is what
# lets you watch the 5-minute dedup window reject an identical repeated send.
#
# Sending to a FIFO queue requires a message_group_id. Messages sharing a group
# are strictly ordered; different groups are processed in parallel. Say to
# yourself why that matters, given FIFO's 300 TPS per-partition ceiling.
