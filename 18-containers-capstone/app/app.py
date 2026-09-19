"""
The capstone application. I wrote this so your time goes on the infrastructure.

Designed so that each infrastructure PHASE lights up a new endpoint, and every
endpoint tells you plainly what is missing if its phase is not built yet:

    GET  /          who answered (task hostname + IP)  -> works from phase 3
    GET  /health    200, no dependencies                -> ALB health check target
    GET  /db        write a row to Postgres, count rows -> phase 4
    GET  /cache     increment a Redis counter           -> phase 4
    POST /upload    put a file in S3                    -> phase 5

Configuration comes ONLY from environment variables set in the ECS task
definition. There is no config file and no secret in this code. DB_PASSWORD in
particular arrives via the task definition's `secrets` block, pulled from the
Secrets Manager secret that RDS itself created - Terraform never sees it.
"""
import os
import socket
import time
import uuid

from flask import Flask, jsonify, request

app = Flask(__name__)

HOST = socket.gethostname()
try:
    IP = socket.gethostbyname(HOST)
except Exception:  # noqa: BLE001
    IP = "unknown"


def _missing(*names):
    gaps = [n for n in names if not os.environ.get(n)]
    return None if not gaps else (jsonify(error="not configured yet", missing=gaps, served_by=HOST), 503)


@app.get("/")
def root():
    return jsonify(app="capstone", served_by=HOST, ip=IP, image_tag=os.environ.get("IMAGE_TAG", "?"))


@app.get("/health")
def health():
    return jsonify(status="ok"), 200


@app.get("/db")
def db():
    if (m := _missing("DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD")):
        return m
    import psycopg2  # imported lazily so /health never depends on it

    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "5432")),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
        sslmode="require",
    )
    with conn, conn.cursor() as cur:
        cur.execute("CREATE TABLE IF NOT EXISTS hits (id SERIAL PRIMARY KEY, host TEXT, ts BIGINT)")
        cur.execute("INSERT INTO hits (host, ts) VALUES (%s, %s)", (HOST, int(time.time())))
        cur.execute("SELECT COUNT(*) FROM hits")
        (count,) = cur.fetchone()
    conn.close()
    return jsonify(db="postgres", rows=count, served_by=HOST)


@app.get("/cache")
def cache():
    if (m := _missing("REDIS_HOST")):
        return m
    import redis  # lazy

    r = redis.Redis(host=os.environ["REDIS_HOST"], port=int(os.environ.get("REDIS_PORT", "6379")),
                    socket_connect_timeout=3)
    n = r.incr("hits")
    return jsonify(cache="redis", counter=n, served_by=HOST)


@app.post("/upload")
def upload():
    if (m := _missing("UPLOAD_BUCKET")):
        return m
    import boto3  # lazy

    key = f"uploads/{int(time.time())}-{uuid.uuid4().hex[:8]}.txt"
    body = request.get_data() or b"hello from capstone"
    boto3.client("s3").put_object(Bucket=os.environ["UPLOAD_BUCKET"], Key=key, Body=body)
    return jsonify(uploaded=key, bytes=len(body), served_by=HOST), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
