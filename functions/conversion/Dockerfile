# ============================================================================
# Dockerfile for CSV to Parquet Conversion Lambda
# ============================================================================
# Base image: AWS Lambda Python 3.11
FROM public.ecr.aws/lambda/python:3.11

# Copy requirements file
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}/

# Set the Lambda handler
CMD [ "lambda_function.lambda_handler" ]
