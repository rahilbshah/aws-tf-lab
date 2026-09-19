# ==========================================================================
# PHASE 2 — your own image, in your own registry.
#
# In 17-ecs-alb you pulled a public image from Docker Hub anonymously. Here
# you build one and push it to ECR. This is the step that turns "run a
# container" into "deploy MY application", and it is the part of the
# containers topic the exam cares about most: IAM-authenticated pulls, no
# registry credentials stored anywhere.
# ==========================================================================

# TODO(21) aws_ecr_repository.app
#          name = var.name
#          image_tag_mutability = "MUTABLE"     (so `v1` can be re-pushed while you iterate;
#                                                production uses IMMUTABLE + a new tag per build)
#          image_scanning_configuration { scan_on_push = true }
#          force_delete = true                  (so `terraform destroy` works while images exist)
#
#          Then OUTPUT its repository_url - you need it for the docker push.
#
# AFTER APPLY — build and push (your Mac is arm64, so this is a native build,
# and the task definition will say architectures arm64 to match):
#
#   REPO=$(terraform output -raw ecr_repository_url)
#   aws ecr get-login-password --region us-east-1 \
#     | docker login --username AWS --password-stdin ${REPO%%/*}
#   docker build --platform linux/arm64 -t $REPO:v1 ./app
#   docker push $REPO:v1
#
#   The `get-login-password` line is the whole ECR-vs-Docker-Hub lesson in one
#   command: your IAM identity minted a 12-hour registry token. No username,
#   no stored password, nothing to rotate.
#
# THE TRAP TO NOTICE: if you build without --platform linux/arm64 on an
# Apple Silicon Mac you still get arm64 (native), but on an Intel machine you
# would get x86_64, the task definition would say arm64, and the task would
# fail with "exec format error" - a runtime failure that looks nothing like an
# architecture mismatch. Set --platform explicitly, always.
