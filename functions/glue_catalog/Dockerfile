# ============================================================================
# Dockerfile for Glue Catalog Management Lambda
# ============================================================================
FROM public.ecr.aws/lambda/python:3.11

# Install system dependencies for building Python packages
RUN yum install -y gcc gcc-c++ make python3-devel && \
    yum clean all && \
    rm -rf /var/cache/yum

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip

COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r requirements.txt

COPY lambda_function.py ${LAMBDA_TASK_ROOT}/

CMD [ "lambda_function.lambda_handler" ]