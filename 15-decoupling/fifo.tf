###############################################################################
# Optional — a FIFO queue, for the ordering and deduplication demo
###############################################################################

# TODO(6): aws_sqs_queue with fifo_queue = true.
#          The name MUST end in ".fifo" or the apply fails.
#          Set content_based_deduplication so you can watch the 5-minute
#          dedup window reject a repeated send.
#
#          Sending to it needs a message_group_id — messages sharing a group
#          are strictly ordered, different groups run in parallel. That is how
#          you buy throughput back from the 300 TPS limit.
