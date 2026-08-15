# 09.2 Advanced — S3 EVENT NOTIFICATIONS (S3 -> SQS)
#
# S3 can push a message whenever an object is created/deleted. Destinations:
# SNS, SQS, Lambda, or EventBridge. We use SQS because you can READ the message
# with one CLI call — no Lambda code needed to see the result.

# ---------------------------------------------------------------------------
# 1. The queue that will receive the events.
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "events" {
  name = "s3-events-${data.aws_caller_identity.current.account_id}"

  # How long a consumer "hides" a message while processing it. 30s is the
  # default; irrelevant for our demo but this is the knob real consumers tune.
  visibility_timeout_seconds = 30

  tags = {
    Name = "s3-events"
  }
}

# ---------------------------------------------------------------------------
# 2. THE GOTCHA: a resource policy letting S3 write to the queue.
#
# The queue is owned by you, not by S3 — so by default S3 has no permission to
# send it anything. This is a RESOURCE-based policy (attached to the queue),
# the same idea as an S3 bucket policy: it says WHO may act on THIS resource.
#
# The `aws:SourceArn` condition is the important security bit: without it, ANY
# bucket in ANY account could publish to your queue (the "confused deputy"
# problem from 01-iam). Scoping to this bucket's ARN closes that.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "queue_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.events.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.this.arn] # only THIS bucket may publish
    }
  }
}

resource "aws_sqs_queue_policy" "events" {
  queue_url = aws_sqs_queue.events.id
  policy    = data.aws_iam_policy_document.queue_policy.json
}

# ---------------------------------------------------------------------------
# 3. Wire the bucket to the queue.
#
# NOTE: only ONE aws_s3_bucket_notification per bucket — this resource manages
# the bucket's ENTIRE notification config. If you later add an SNS topic or
# Lambda, add another block INSIDE this resource; a second resource would
# silently overwrite this one.
#
# depends_on matters: S3 validates it can actually write to the queue at
# creation time. If the queue policy doesn't exist yet, apply fails with
# "Unable to validate the following destination configurations".
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_notification" "this" {
  bucket = aws_s3_bucket.this.id

  queue {
    queue_arn = aws_sqs_queue.events.arn

    # s3:ObjectCreated:* covers Put, Post, Copy and CompleteMultipartUpload.
    # s3:ObjectRemoved:* covers deletes (incl. the delete-marker case).
    events = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

    # Optional filters so you don't get an event for every object in the
    # bucket. You can also add filter_suffix = ".txt" to narrow further.
    filter_prefix = "uploads/"
  }

  depends_on = [aws_sqs_queue_policy.events]
}
