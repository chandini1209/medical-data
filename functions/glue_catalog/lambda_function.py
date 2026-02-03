import boto3
import os
import json
import time
from urllib.parse import unquote_plus

# AWS Clients
s3 = boto3.client("s3")
glue = boto3.client("glue")

# Environment Variables
DB = os.environ["GLUE_DATABASE_NAME"]
TABLE = os.environ["GLUE_TABLE_NAME"]
BASE_PREFIX = os.environ["BASE_S3_PREFIX"]  # e.g., "record_folders/"

# ---------------- LAMBDA HANDLER ----------------
def lambda_handler(event, context):
    print("Event received:")
    print(json.dumps(event, indent=2))

    # Get S3 info from trigger
    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = unquote_plus(record["s3"]["object"]["key"])
    print(f"S3 bucket: {bucket}, key: {key}")

    # 1️⃣ Ensure database exists
    create_database()

    # 2️⃣ Ensure table exists
    base_location = f"s3://{bucket}/{BASE_PREFIX}/"
    create_table(base_location)

    # 3️⃣ Scan S3 for all version folders (normalized)
    versions = get_versions(bucket, BASE_PREFIX)
    print("Versions found in S3:", versions)

    # 4️⃣ Add partitions for all versions
    added_versions = []
    for version in versions:
        partition_location = f"s3://{bucket}/{BASE_PREFIX}/Record_{version}/"
        if add_partition(version, partition_location):
            added_versions.append(version)

    return {"status": "SUCCESS", "versions_added": added_versions}


# ---------------- DATABASE ----------------
def create_database():
    try:
        glue.get_database(Name=DB)
        print(f"Database {DB} exists")
    except glue.exceptions.EntityNotFoundException:
        glue.create_database(
            DatabaseInput={"Name": DB, "Description": f"Created by Lambda"}
        )
        print(f"Database {DB} created")


# ---------------- TABLE ----------------
def create_table(location):
    try:
        glue.get_table(DatabaseName=DB, Name=TABLE)
        print(f"Table {TABLE} exists")
        return
    except glue.exceptions.EntityNotFoundException:
        pass

    # Table columns
    columns = [
        "pt_code","hlt_code","hlgt_code","soc_code",
        "pt_name","hlt_name","hlgt_name","soc_name",
        "soc_abbrev","pt_soc_code","primary_soc_fg",
        "llt_code","llt_name","llt_currency","name"
    ]
    schema = [{"Name": col, "Type": "string"} for col in columns]

    table_input = {
        "Name": TABLE,
        "TableType": "EXTERNAL_TABLE",
        "Parameters": {"classification": "parquet", "parquet.compress": "SNAPPY"},
        "PartitionKeys": [{"Name": "version", "Type": "string"}],
        "StorageDescriptor": {
            "Columns": schema,
            "Location": location,  # Base location remains unchanged
            "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
            "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
            "SerdeInfo": {
                "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
            },
            "StoredAsSubDirectories": True
        }
    }

    glue.create_table(DatabaseName=DB, TableInput=table_input)
    print(f"Table {TABLE} created")


# ---------------- GET VERSIONS ----------------
def get_versions(bucket, prefix):
    """Scan S3 and normalize version folders as X.Y"""
    paginator = s3.get_paginator("list_objects_v2")
    versions = set()

    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            # Check if key contains a version folder
            if "Record_" in key:
                folder_part = key.split("Record_")[1].split("/")[0]  # Get folder name
                # Normalize to X.Y format
                if "." not in folder_part:
                    folder_part = f"{folder_part}.0"
                versions.add(folder_part)

    return sorted(versions)


# ---------------- PARTITION ----------------
def add_partition(version, location):
    """Add partition if it does not exist"""
    try:
        glue.get_partition(DatabaseName=DB, TableName=TABLE, PartitionValues=[version])
        print(f"Partition {version} already exists")
        return False
    except glue.exceptions.EntityNotFoundException:
        pass

    glue.batch_create_partition(
        DatabaseName=DB,
        TableName=TABLE,
        PartitionInputList=[{
            "Values": [version],
            "StorageDescriptor": {
                "Location": location,
                "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
                "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
                "SerdeInfo": {
                    "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
                }
            }
        }]
    )
    print(f"Partition {version} created")
    return True
