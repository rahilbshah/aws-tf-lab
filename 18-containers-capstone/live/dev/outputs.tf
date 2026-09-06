# TODO(16) Re-export what you will need at the shell and in later phases:
#            vpc_id, public_subnet_ids, private_subnet_ids, isolated_subnet_ids
#          e.g.  value = module.network.vpc_id
#
#          A root module's outputs are how you hand values to a human or to
#          another tool. You will use these in phase 3 to sanity-check what
#          the ALB and the ECS service are being given.
#
# ==========================================================================
# HOW TO RUN THIS, once the module is written
#
#   cd live/dev
#   terraform init                       # downloads the provider, links the module,
#                                        # and connects to the S3 backend
#   terraform plan  -var-file=dev.tfvars
#   terraform apply -var-file=dev.tfvars
#
# WHAT TO LOOK AT AFTERWARDS:
#
# 1. The state is not on your laptop:
#      aws s3 ls s3://tfstate-626210706989/live/dev/
#      ls terraform.tfstate            # should NOT exist
#
# 2. Resource addresses are namespaced by the module:
#      terraform state list
#    Everything reads module.network.aws_subnet.public["us-east-1a"]. That
#    address - keyed by AZ NAME, not by an index - is the payoff of for_each,
#    and it is what makes adding a third AZ a safe change rather than a
#    renumbering that destroys subnets.
#
# 3. The isolated tier really is isolated. In the console, open the isolated
#    route table and confirm there is NO 0.0.0.0/0 entry - only the VPC-local
#    route and the S3 prefix list. That empty space is the security control.
#
# 4. Then destroy it, because the NAT gateway bills hourly:
#      terraform destroy -var-file=dev.tfvars
# ==========================================================================
