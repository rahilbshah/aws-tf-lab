# TODO(14) output "api_url"  = aws_apigatewayv2_api.this.api_endpoint
#          output "table_name" = the table name
#
# ==========================================================================
# TRY IT, once applied
#
#   API=$(terraform output -raw api_url)
#
#   # create two notes for one user, one for another
#   curl -s -XPOST $API/notes -d '{"userId":"rahil","title":"first","body":"hello"}'
#   curl -s -XPOST $API/notes -d '{"userId":"rahil","title":"second","body":"again"}'
#   curl -s -XPOST $API/notes -d '{"userId":"someone-else","title":"theirs"}'
#
#   # list one user's notes — ONE partition, one Query
#   curl -s $API/notes/rahil | python3 -m json.tool
#
#   # fetch exactly one — needs the FULL primary key
#   curl -s $API/notes/rahil/<noteId-from-above> | python3 -m json.tool
#
# WHAT TO NOTICE
#
# 1. GET /notes/rahil returns rahil's notes and NOT someone-else's, without
#    any filter in the code. That is the partition key doing the work. In SQL
#    you would have written WHERE user_id = ... and the database would have
#    had to find those rows. Here they were already stored together.
#
# 2. Try fetching a note with the right noteId but the WRONG userId. It 404s,
#    because GetItem needs the complete primary key and you gave it half.
#    That is the constraint that forced your schema.
#
# 3. Now the question the whole lab exists to make concrete: how would you
#    serve "get me note X, I do not know which user it belongs to"? Your table
#    cannot answer it without scanning everything. THAT is what a GSI is for -
#    a different partition key over the same data. You do not have to build
#    it; just be able to say what it would look like.
#
# 4. CloudWatch -> /aws/lambda/notes-api. Every invocation logged, plus
#    REPORT lines showing Duration, Billed Duration, Memory Size and Max
#    Memory Used. Look at Max Memory Used against your 128 MB - that gap is
#    exactly what the memory/CPU tuning conversation was about.
#
# 5. Then destroy it. Nothing here bills hourly, so there is no rush - but
#    the DynamoDB table is the one thing holding state you might miss later.
# ==========================================================================
