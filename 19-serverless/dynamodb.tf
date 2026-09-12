# ==========================================================================
# 19-serverless — API Gateway -> Lambda -> DynamoDB
#
# BUILD ORDER: dynamodb.tf -> iam.tf -> lambda.tf -> apigateway.tf ->
# outputs.tf. Numbered 1..12 continuously across those files.
#
# COST: effectively nothing. DynamoDB on-demand charges per request, Lambda's
# free tier covers a million invocations a month, and HTTP API is about a
# dollar per million requests. A whole session here is pennies at most. This
# is the cheapest lab you have built - no NAT gateway, no ALB, nothing billing
# by the hour. You can leave it up while you experiment.
#
# THE ACTUAL EXERCISE IS THIS FILE. Everything else is wiring. Go and read
# app/handler.py first - the three routes it serves ARE your access patterns,
# and in DynamoDB the access patterns determine the key schema. You do not get
# to design the table and then figure out the queries, the way you would with
# SQL. That inversion is the whole point.
# ==========================================================================

# TODO(1) aws_dynamodb_table.notes
#
#         name         = var.name
#         billing_mode = "PAY_PER_REQUEST"
#
#         DESIGN CHOICE, already made for you and worth knowing why:
#         PAY_PER_REQUEST is on-demand. The alternative, "PROVISIONED",
#         requires read_capacity and write_capacity arguments and bills for
#         that capacity whether you use it or not. For a lab with unpredictable,
#         near-zero traffic, on-demand is both cheaper and one less thing to
#         size. In production with a known steady load, provisioned + auto
#         scaling is usually cheaper per request.
#
#         NOW THE PART YOU HAVE TO WORK OUT.
#
#         You need `hash_key`, possibly `range_key`, and an `attribute` block
#         for each key attribute (with type = "S" for string).
#
#         Terraform gotcha that confuses everyone once: you declare an
#         `attribute` block ONLY for attributes used in a key or an index.
#         DynamoDB is schemaless for everything else - `title`, `body` and
#         `createdAt` are written by the handler and must NOT appear here.
#         If you declare an attribute that is not part of a key, apply fails.
#
#         To decide the keys, answer these in order:
#
#           a) "GET /notes/{userId}" must return EVERY note for one user in a
#              single query. Which attribute has to be the partition key for
#              that to be one cheap lookup rather than a full table Scan?
#
#           b) "GET /notes/{userId}/{noteId}" must fetch exactly one item.
#              GetItem needs the COMPLETE primary key. If the partition key
#              alone were the whole key, could two notes for the same user
#              even coexist? What does that force?
#
#           c) Sanity-check your answer against the handler: it calls
#              query(KeyConditionExpression=Key('userId').eq(...)) for the
#              list, and get_item(Key={'userId': ..., 'noteId': ...}) for the
#              single fetch. A Query needs the partition key; a GetItem needs
#              the full primary key. Does your schema make both legal?
#
#         Then think about whether it is a GOOD key, not just a legal one:
#         every note for one user lands in one partition. What happens if one
#         user has ten million notes and everyone else has three? That is the
#         hot partition problem, and it is the thing DynamoDB design is
#         actually about.

# TODO(2) OPTIONAL — a stream. Skip on the first pass.
#         Add to the table:  stream_enabled = true
#                            stream_view_type = "NEW_AND_OLD_IMAGES"
#         It costs nothing extra while nothing consumes it, and it makes the
#         change-data-capture idea concrete: turn it on, write an item, and
#         look at the stream in the console. Remember you CANNOT change
#         stream_view_type later without disabling and recreating the stream.
