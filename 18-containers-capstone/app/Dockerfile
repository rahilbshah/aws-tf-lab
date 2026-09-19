# Built for arm64 (Graviton Fargate) - native on Apple Silicon.
FROM python:3.13-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

ENV PORT=8080
EXPOSE 8080

# gunicorn, not flask's dev server: multiple workers, proper signal handling so
# ECS can stop the task cleanly. Bind to 0.0.0.0 or the ALB can never reach it.
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
