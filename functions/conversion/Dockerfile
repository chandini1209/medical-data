# Test with minimal requirements
cat > functions/conversion/requirements.txt << 'EOF'
boto3==1.34.0
EOF

cat > functions/conversion/Dockerfile << 'EOF'
FROM public.ecr.aws/lambda/python:3.11

COPY requirements.txt ${LAMBDA_TASK_ROOT}/

RUN pip install --no-cache-dir -r requirements.txt

COPY lambda_function.py ${LAMBDA_TASK_ROOT}/

CMD [ "lambda_function.lambda_handler" ]
EOF