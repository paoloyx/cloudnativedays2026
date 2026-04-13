FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir PyYAML kratix-sdk

COPY scripts/pipeline.py .

ENTRYPOINT ["python", "pipeline.py"]
