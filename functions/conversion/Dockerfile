# ============================================================================
# Dockerfile for CSV to Parquet Conversion Lambda
# ============================================================================
FROM public.ecr.aws/lambda/python:3.11

# Install build dependencies
RUN yum install -y gcc gcc-c++ cmake

# Upgrade pip
RUN pip install --upgrade pip

# Copy requirements file
COPY requirements.txt ${LAMBDA_TASK_ROOT}/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Clean up build dependencies to reduce image size
RUN yum remove -y gcc gcc-c++ cmake && \
    yum clean all && \
    rm -rf /var/cache/yum

# Copy function code
COPY lambda_function.py ${LAMBDA_TASK_ROOT}/

# Set the Lambda handler
CMD [ "lambda_function.lambda_handler" ]