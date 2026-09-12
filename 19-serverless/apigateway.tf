# ==========================================================================
# The front door. HTTP API, not REST.
#
# You now know the elimination rule: HTTP API is the cheap fast one, and if a
# scenario needs caching, API keys, usage plans, WAF or a private VPC-only
# API then it must be REST. This lab needs none of those, so HTTP API it is -
# and it is roughly a third of the price.
# ==========================================================================

# TODO(9) aws_apigatewayv2_api.this          <- note "v2" = HTTP API
#         name          = var.name
#         protocol_type = "HTTP"
#
#         The v1 resources (aws_api_gateway_rest_api and friends) are REST.
#         Getting the resource family wrong is the most common first mistake
#         here, and the error messages are unhelpful because both families are
#         valid Terraform.

# TODO(10) aws_apigatewayv2_integration.lambda
#          api_id                 = (9)
#          integration_type       = "AWS_PROXY"
#          integration_uri        = the Lambda's invoke_arn
#          payload_format_version = "2.0"
#
#          AWS_PROXY means "hand the whole request to Lambda and return
#          whatever it gives back". The alternative is mapping templates,
#          where API Gateway transforms the request - that is REST-API
#          territory and far more work.
#
#          payload_format_version MUST be "2.0" here. handler.py reads
#          event["routeKey"] and event["pathParameters"], which is the 2.0
#          shape. Format 1.0 nests things differently and the handler will
#          404 on every request while looking perfectly healthy.
#
#          Use invoke_arn, NOT arn. They are different strings and this is a
#          classic hour-long debugging session.

# TODO(11) aws_apigatewayv2_route — THREE of them, matching handler.py exactly:
#            "POST /notes"
#            "GET /notes/{userId}"
#            "GET /notes/{userId}/{noteId}"
#          each with target = "integrations/${aws_apigatewayv2_integration.lambda.id}"
#
#          Consider for_each over a set of the three route keys rather than
#          three near-identical blocks - same argument as the subnets in 18-.
#
#          The route strings must match the handler's `if route ==` checks
#          character for character, braces included. That coupling is real and
#          it is why the handler prints the routeKey in its 404 - so you can
#          see what actually arrived.

# TODO(12) aws_apigatewayv2_stage.default
#          api_id      = (9)
#          name        = "$default"
#          auto_deploy = true
#
#          "$default" is a special stage name that serves at the API root with
#          no /stage-name prefix in the URL. auto_deploy is the HTTP-API-only
#          feature from the comparison table - REST APIs need an explicit
#          deployment resource, which is a classic "I applied but nothing
#          changed" trap.

# TODO(13) aws_lambda_permission.apigw
#          statement_id  = "AllowExecutionFromAPIGateway"
#          action        = "lambda:InvokeFunction"
#          function_name = the function name
#          principal     = "apigateway.amazonaws.com"
#          source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
#
#          STOP AND RECOGNISE THIS. It is the confused deputy, for the fifth
#          time: 09-s3 events, 01-iam-lab, 11-cloudfront OAC, 15-decoupling
#          SNS->SQS, and now here. The principal "apigateway.amazonaws.com" is
#          THE SAME PRINCIPAL for every AWS customer on earth. Without
#          source_arn, you have granted every API Gateway in the world
#          permission to invoke your function. source_arn narrows it to YOUR
#          api. Write it without looking - you know this pattern now.
#
#          Note execution_arn, not arn. Again two different strings.
