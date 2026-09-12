# ==========================================================================
# The function itself.
# ==========================================================================

# TODO(6) data.archive_file.handler
#         type        = "zip"
#         source_file = "${path.module}/app/handler.py"
#         output_path = "${path.module}/build/handler.zip"
#
#         Lambda wants a zip, not a .py. This data source builds one at plan
#         time so you never hand-zip anything. Add build/ to .gitignore -
#         it is a build artifact, not source.
#
#         boto3 is already present in the Lambda Python runtime, so this
#         function has no dependencies to package. The moment you need a third
#         party library you would either add a LAYER or switch to a container
#         image - that is what layers are for and it is exam-relevant.

# TODO(7) aws_cloudwatch_log_group.lambda
#         name              = "/aws/lambda/${var.name}"     <- this EXACT shape
#         retention_in_days = var.log_retention_days
#
#         The name is not a convention you may vary. Lambda writes to
#         /aws/lambda/<function-name> and nowhere else. Create it yourself so
#         that retention is set and terraform destroy takes it with you -
#         exactly the reasoning from 17-ecs-alb.

# TODO(8) aws_lambda_function.notes
#         function_name    = var.name
#         role             = the role ARN from (3)
#         filename         = data.archive_file.handler.output_path
#         source_code_hash = data.archive_file.handler.output_base64sha256
#         handler          = "handler.handler"    # <file>.<function>
#         runtime          = "python3.13"   # verified supported (EOL Jun 2029)
#         architectures    = ["arm64"]      # <- see the note below
#         memory_size      = var.lambda_memory_mb
#         timeout          = var.lambda_timeout_seconds
#
#         environment {
#           variables = { TABLE_NAME = the table name from (1) }
#         }
#
#         depends_on = [aws_cloudwatch_log_group.lambda]
#
#         WHY source_code_hash MATTERS: without it, Terraform compares only the
#         filename, sees no change, and silently refuses to deploy your edited
#         code. You edit handler.py, apply, get "No changes", and spend twenty
#         minutes debugging a function that is still running yesterday's code.
#         The hash is what makes Terraform notice.
#
#         WHY depends_on: without it Terraform may create the function first,
#         the function may be invoked, and Lambda will auto-create the log
#         group WITHOUT retention - then your aws_cloudwatch_log_group create
#         fails because it already exists.
#
#         WHY arm64: the docs confirm "All supported Lambda runtimes support
#         both x86_64 and arm64 architectures", and Graviton is cheaper per
#         GB-second. Your Mac is arm64 too, so if you ever move to a container
#         image the build is native rather than emulated. For a pure-Python
#         function with no compiled dependencies there is no downside at all -
#         which is exactly why it is a free win here and not always elsewhere.
#         Try flipping it to x86_64 and back and read the plan: architectures
#         forces a function update, not a replacement.
#
#         NOTE what is absent: no vpc_config. Deliberate. See the note in (4).
