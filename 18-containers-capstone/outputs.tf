# TODO(49) outputs — add each as its phase arrives:
#   ecr_repository_url    (phase 2 — you need it for docker push)
#   alb_url               (phase 3)
#   db_secret_arn         (phase 4 — aws_db_instance.this.master_user_secret[0].secret_arn,
#                          so you can `aws secretsmanager get-secret-value` and SEE the password
#                          RDS made, and confirm it is nowhere in your files)
#   uploads_bucket        (phase 5)
#   cloudfront_url        (phase 6 — "https://${aws_cloudfront_distribution.this.domain_name}")
