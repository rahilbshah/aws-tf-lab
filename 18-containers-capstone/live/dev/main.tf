# ==========================================================================
# live/dev — the ROOT module for the dev environment.
#
# This file should stay boring. Its job is to wire modules together and pass
# environment-specific values in. If real resource logic starts accumulating
# here, that is the signal it belongs in a module instead.
# ==========================================================================

# TODO(15) module "network"
#          source = "../../modules/network"
#
#          Pass through: name, vpc_cidr, az_count, nat_gateway_count,
#          enable_flow_logs.
#
#          Note there is no `version` argument - that is for registry modules.
#          A local path module is versioned by your git history.
#
#          Run `terraform init` after adding this. Local modules still need
#          init; Terraform records them in .terraform/modules/modules.json.
#          Forgetting this is the most common "why does it say the module does
#          not exist" moment.

# NOT YET — these arrive in later phases, listed so the shape is visible:
#   module "data"         (phase 4)  RDS + ElastiCache in the isolated subnets
#   module "ecs_cluster"  (phase 3)
#   module "ecs_service"  (phase 3)
#   edge.tf               (phase 5)  ALB + CloudFront, NOT a module - one per
#                                    environment, nothing to reuse
