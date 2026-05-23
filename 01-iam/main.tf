resource "aws_iam_user" "alice" {
  name = "alice"
}

resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_user_group_membership" "alice_developers" {
  user   = aws_iam_user.alice.name
  groups = [aws_iam_group.developers.name]
}

data "aws_iam_policy_document" "s3_example_read" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
  }
}

resource "aws_iam_policy" "s3_bucket_read" {
  name   = "s3_bucket_read_policy"
  policy = data.aws_iam_policy_document.s3_example_read.json
}

resource "aws_iam_group_policy_attachment" "developers_s3" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_bucket_read.arn
}