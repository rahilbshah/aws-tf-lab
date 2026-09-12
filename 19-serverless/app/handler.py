"""
A tiny notes API. This is the APPLICATION, not the lesson - I wrote it so you
can spend your time on the infrastructure.

READ THIS BEFORE YOU DESIGN THE TABLE. The handler supports exactly three
operations, and those three ARE the access patterns your table must serve:

    POST /notes                    create a note for a user
    GET  /notes/{userId}           list ALL notes for one user
    GET  /notes/{userId}/{noteId}  fetch ONE specific note

Notice what the code does for each:
  - listing uses  table.query(KeyConditionExpression=Key('userId').eq(...))
  - fetching one uses  table.get_item(Key={'userId': ..., 'noteId': ...})

Those two calls are only possible if the key schema is shaped a particular
way. Work out which way before you write dynamodb.tf - that is the exercise.
"""
import json
import os
import time
import uuid

import boto3
from boto3.dynamodb.conditions import Key

TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def _resp(status, body):
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body, default=str),
    }


def handler(event, context):
    # HTTP API (payload format 2.0) puts the matched route here, e.g. "GET /notes/{userId}"
    route = event.get("routeKey", "")
    params = event.get("pathParameters") or {}

    try:
        if route.startswith("POST /notes"):
            body = json.loads(event.get("body") or "{}")
            if not body.get("userId"):
                return _resp(400, {"error": "userId is required"})

            item = {
                "userId": body["userId"],
                "noteId": str(uuid.uuid4()),
                "title": body.get("title", "untitled"),
                "body": body.get("body", ""),
                "createdAt": int(time.time()),
            }
            TABLE.put_item(Item=item)
            return _resp(201, item)

        if route == "GET /notes/{userId}":
            # ONE query, one partition. This is the cheap, fast DynamoDB read.
            out = TABLE.query(KeyConditionExpression=Key("userId").eq(params["userId"]))
            return _resp(200, {"count": out["Count"], "items": out["Items"]})

        if route == "GET /notes/{userId}/{noteId}":
            out = TABLE.get_item(
                Key={"userId": params["userId"], "noteId": params["noteId"]}
            )
            if "Item" not in out:
                return _resp(404, {"error": "not found"})
            return _resp(200, out["Item"])

        return _resp(404, {"error": f"no route for {route}"})

    except Exception as exc:  # noqa: BLE001 - lab code, log everything
        print(f"ERROR handling {route}: {exc}")
        return _resp(500, {"error": str(exc)})
