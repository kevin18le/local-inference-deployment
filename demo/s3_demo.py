import json
import os
from datetime import datetime
import boto3
from botocore.client import Config

S3_ENDPOINT = os.getenv("S3_ENDPOINT", "http://localhost:9000")
ACCESS_KEY = os.getenv("AWS_ACCESS_KEY_ID", "minioadmin")
SECRET_KEY = os.getenv("AWS_SECRET_ACCESS_KEY", "minioadmin123")
BUCKET = os.getenv("S3_BUCKET", "artifacts")

def s3_client():
    # signature_version='s3v4' is important for many S3-compatible endpoints
    return boto3.client(
        "s3",
        endpoint_url=S3_ENDPOINT,
        aws_access_key_id=ACCESS_KEY,
        aws_secret_access_key=SECRET_KEY,
        config=Config(signature_version="s3v4"),
        region_name="us-east-1",
    )

def ensure_bucket(client):
    buckets = [b["Name"] for b in client.list_buckets().get("Buckets", [])]
    if BUCKET not in buckets:
        client.create_bucket(Bucket=BUCKET)

def main():
    client = s3_client()
    ensure_bucket(client)

    # Create a small “artifact” payload and upload it
    key = f"runs/{datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}/request.json"
    payload = {
        "project": "mini-inference-platform",
        "purpose": "S3 semantics practice with MinIO",
        "example": {
            "model": "Qwen2.5-0.5B-Instruct (placeholder)",
            "prompt": "Say hello in a professional tone."
        },
    }
    body = json.dumps(payload, indent=2).encode("utf-8")

    client.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=body,
        ContentType="application/json",
    )
    print(f"Uploaded: s3://{BUCKET}/{key}")

    # List objects under the prefix
    resp = client.list_objects_v2(Bucket=BUCKET, Prefix="runs/")
    for item in resp.get("Contents", []):
        print(" -", item["Key"], item["Size"], "bytes")

    # Generate a presigned URL (like you’d do for frontends / temporary access)
    url = client.generate_presigned_url(
        ClientMethod="get_object",
        Params={"Bucket": BUCKET, "Key": key},
        ExpiresIn=300,  # 5 minutes
    )
    print("\nPresigned GET URL (valid 5 minutes):")
    print(url)

if __name__ == "__main__":
    main()
