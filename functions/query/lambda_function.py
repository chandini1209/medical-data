import boto3
import os
import json
import time
import base64

# AWS Clients
athena_client = boto3.client('athena')

# Environment Variables
DATABASE = os.environ.get('DATABASE')
OUTPUT_LOCATION = os.environ.get('OUTPUT_LOCATION')


def clean_value(value):
    """Cleans Athena output values by handling escaped quotes."""
    if isinstance(value, str):
        value = value.strip()
        # Remove wrapping quotes if present
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        # Replace double double-quotes with single quote
        value = value.replace('""', '"')
    return value


def convert_to_json(result_data):
    """Converts Athena query result into JSON format with cleaned values."""
    if not result_data or len(result_data) < 2:
        return []  # Return empty list if no data

    # Extract column names from first row
    columns = [col.get('VarCharValue', '') for col in result_data[0]['Data']]

    json_data = []
    for row in result_data[1:]:
        values = [clean_value(col.get('VarCharValue', '')) for col in row['Data']]
        row_dict = dict(zip(columns, values))
        json_data.append(row_dict)

    return json_data


def lambda_handler(event, context):
    """
    Main handler for Athena query execution via API Gateway
    """
    print(f"Received event: {json.dumps(event)}")

    try:
        # Parse request body
        if 'body' in event:
            # Handle Base64-encoded body
            if event.get('isBase64Encoded', False):
                body = json.loads(base64.b64decode(event['body']).decode('utf-8'))
            else:
                body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event

        # Get query from request (support both 'Query' and 'query')
        query = body.get('Query') or body.get('query')
        
        if not query:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'No query provided',
                    'example': {
                        'query': 'SELECT * FROM table_name LIMIT 10'
                    }
                })
            }

        # Validate environment variables
        if not DATABASE or not OUTPUT_LOCATION:
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing environment variables',
                    'details': 'DATABASE and OUTPUT_LOCATION must be set'
                })
            }

        print(f"Executing query: {query}")
        print(f"Database: {DATABASE}")
        print(f"Output location: {OUTPUT_LOCATION}")

        # Start query execution
        response = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={'Database': DATABASE},
            ResultConfiguration={'OutputLocation': OUTPUT_LOCATION}
        )

        query_execution_id = response['QueryExecutionId']
        print(f"Query execution ID: {query_execution_id}")

        # Wait for query to complete (with timeout)
        max_wait_time = 60  # 60 seconds timeout
        start_time = time.time()
        
        while True:
            if time.time() - start_time > max_wait_time:
                return {
                    'statusCode': 504,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'error': 'Query timeout',
                        'query_execution_id': query_execution_id,
                        'message': 'Query took longer than 60 seconds'
                    })
                }

            execution_status = athena_client.get_query_execution(
                QueryExecutionId=query_execution_id
            )
            status = execution_status['QueryExecution']['Status']['State']
            
            print(f"Query status: {status}")

            if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                break

            time.sleep(1)

        # Handle query failure
        if status != 'SUCCEEDED':
            reason = execution_status['QueryExecution']['Status'].get(
                'StateChangeReason', 
                'Unknown error'
            )
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Query failed',
                    'status': status,
                    'reason': reason,
                    'query_execution_id': query_execution_id
                })
            }

        # Fetch query results with pagination
        result_data = []
        next_token = None

        while True:
            result_params = {'QueryExecutionId': query_execution_id}
            if next_token:
                result_params['NextToken'] = next_token

            result_response = athena_client.get_query_results(**result_params)
            result_data.extend(result_response['ResultSet']['Rows'])
            
            next_token = result_response.get('NextToken')
            if not next_token:
                break

        print(f"Fetched {len(result_data)} rows (including header)")

        # Convert to JSON
        json_data = convert_to_json(result_data)
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'status': 'success',
                'query': query,
                'row_count': len(json_data),
                'query_execution_id': query_execution_id,
                'data': json_data
            }, default=str)
        }

    except json.JSONDecodeError as e:
        print(f"JSON decode error: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Invalid JSON in request body',
                'details': str(e)
            })
        }
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }