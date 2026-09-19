# 18 — Containers capstone (flat edition)

One root config, one file per concern, explicit resources. **No modules, no
for_each over AZs, no dev/prod split.** The AWS services are the lesson; the
Terraform is deliberately the same style as `17-ecs-alb`.

The one "best practice" kept: the S3 state backend from `bootstrap/`. It is six
lines, it is already built, and it means a laptop failure mid-project loses
nothing.

## Build in phases — each one applies and works on its own

| Phase | Files | You get | Adds to the bill |
|---|---|---|---|
| 1 | `network.tf` `security.tf` | 3-tier VPC, all security groups | NAT gateway $0.045/hr |
| 2 | `ecr.tf` + `app/` | your image in ECR | ~nothing |
| 3 | `alb.tf` `ecs.tf` | app on the internet via ALB (`/` and `/health` work) | ALB $0.0225/hr, Fargate ~$0.012/hr |
| 4 | `data.tf` + task-def secrets | `/db` and `/cache` work; password never seen by Terraform | RDS ~$0.017/hr, ElastiCache ~$0.017/hr |
| 5 | `s3.tf` + task role | `/upload` works | ~nothing |
| 6 | `cloudfront.tf` | HTTPS, and the ALB refuses anyone but CloudFront | ~nothing at lab traffic |
| 7 | `autoscaling.tf` | task count follows CPU | nothing |

Everything up at once is roughly **13¢/hour**. Destroy at the end of each session
(`terraform destroy` — nothing here is protected). Credits are AWS-only and expire
around 2026-10-06.

## Terraform you already know

Everything here you have written before: resources, variables, data sources,
references, `jsonencode` container definitions, `data.aws_iam_policy_document`,
`depends_on`, and the v6-style security group rule resources. **One new thing**,
in phase 7, taught where it appears: `lifecycle { ignore_changes }`.
