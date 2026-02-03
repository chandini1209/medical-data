# ============================================================================
# Dockerfile for CSV to Parquet Conversion Lambda
# ============================================================================
# Base image: AWS Lambda Python 3.11
FROM public.ecr.aws/lambda/python:3.11

# Install system dependencies for building Python packages
RUN yum install -y gcc gcc-c++ make python3-devel && \
    yum clean all && \
    rm -rf /var/cache/yum

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip

# Copy requirements file
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}/

# Set the Lambda handler
CMD [ "lambda_function.lambda_handler" ]