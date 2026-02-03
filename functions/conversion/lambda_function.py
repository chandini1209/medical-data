import pandas as pd
import boto3
from io import BytesIO
import os
import urllib.parse
from datetime import datetime

s3 = boto3.client("s3")

# ================= ENVIRONMENT VARIABLES =================
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]     
OUTPUT_PREFIX = os.environ["OUTPUT_PREFIX"]      

# =========================================================

def lambda_handler(event, context):

    record = event["Records"][0]
    source_bucket = record["s3"]["bucket"]["name"]
    source_key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

    print(f"Processing file: s3://{source_bucket}/{source_key}")

    # Only process CSV files
    if not source_key.lower().endswith(".csv"):
        print("Skipped: Not a CSV file")
        return {"status": "SKIPPED"}

    # ================= READ CSV ==================
    obj = s3.get_object(Bucket=source_bucket, Key=source_key)
    df = pd.read_csv(BytesIO(obj["Body"].read()), dtype=str)
    print(f"Rows loaded: {len(df)}")

    # Normalize column names
    df.columns = df.columns.str.strip().str.lower()
    print("Columns:", df.columns.tolist())

    # ================= FIND VERSION COLUMN ==================
    version_cols = [c for c in df.columns if "version" in c]
    if not version_cols:
        raise Exception("Version column not found")

    version_col = version_cols[0]
    print(f"Using version column: {version_col}")

    # ================= CLEAN VERSION COLUMN ==================
    # Remove non-digit/dot characters, strip spaces, and normalize
    df[version_col] = df[version_col].astype(str).str.replace(r"[^\d.]", "", regex=True).str.strip()
    df[version_col] = df[version_col].apply(lambda x: x if '.' in x else f"{x}.0")

    # Remove invalid rows
    df = df[df[version_col].str.match(r"^\d+(\.\d+)?$")]
    if df.empty:
        print("No valid rows after version cleaning")
        return {"status": "NO_VALID_ROWS"}

    unique_versions = sorted(df[version_col].unique())
    print("Clean versions found:", unique_versions)

    responses = []

    # ================= PROCESS EACH VERSION ==================
    for version in unique_versions:
        filtered_df = df[df[version_col] == version]

        if filtered_df.empty:
            print(f"No rows for version {version}, skipping")
            continue

        # Convert to Parquet
        parquet_buffer = BytesIO()
        try:
            filtered_df.to_parquet(parquet_buffer, engine="pyarrow", index=False, compression="snappy")
        except Exception as e:
            print(f"Error converting version {version} to Parquet: {e}")
            continue
        parquet_buffer.seek(0)

        # Upload to S3
        base_filename = os.path.splitext(os.path.basename(source_key))[0]
        print('base_filename:', base_filename)
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        s3_key = f"{OUTPUT_PREFIX}/Record_{version}/{base_filename}_{timestamp}.parquet"

        try:
            s3.put_object(
                Bucket=OUTPUT_BUCKET,
                Key=s3_key,
                Body=parquet_buffer.getvalue(),
                ContentType="application/octet-stream"
            )
        except Exception as e:
            print(f"Error uploading version {version} to S3: {e}")
            continue

        print(f"Uploaded → s3://{OUTPUT_BUCKET}/{s3_key}")

        responses.append({
            "version": version,
            "rows": len(filtered_df),
            "s3_path": f"s3://{OUTPUT_BUCKET}/{s3_key}"
        })

    return {
        "status": "SUCCESS",
        "files_created": responses
    }