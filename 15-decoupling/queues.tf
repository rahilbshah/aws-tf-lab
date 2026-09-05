###############################################################################
# The queues — one per downstream consumer, plus a dead-letter queue
###############################################################################

# TODO(2): two aws_sqs_queue resources, one per consumer.
#          Set visibility_timeout_seconds from var.visibility_timeout so the
#          "message comes back on its own" behaviour is observable in seconds
#          instead of the 30-second default.
#          Consider for_each over a set of names rather than copy-paste.


# TODO(3): a third aws_sqs_queue as the dead-letter queue, then attach it to
#          the first queue with a redrive_policy using var.max_receive_count.
#
#          redrive_policy takes a JSON STRING — jsonencode({...}) is the
#          idiomatic way to build it. It needs the DLQ's ARN and the count.
#
#          One thing AWS is explicit about: for standard queues a message keeps
#          its ORIGINAL enqueue timestamp when it moves to the DLQ. Given that,
#          what should the DLQ's message_retention_seconds be relative to the
#          source queue's?
