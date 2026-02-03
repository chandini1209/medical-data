# ============================================================================
# Dockerfile for CSV to Parquet Conversion Lambda
# ============================================================================
# Base image: AWS Lambda Python 3.11
FROM public.ecr.aws/lambda/python:3.11

# Copy requirements file
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install system dependencies (gcc compiler), upgrade pip, install Python packages, then clean up
RUN yum install -y gcc gcc-c++ cmake && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    yum remove -y gcc gcc-c++ cmake && \
    yum clean all && \
    rm -rf /var/cache/yum

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}/

# Set the Lambda handler
CMD [ "lambda_function.lambda_handler" ]