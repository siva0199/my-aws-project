import boto3
import os
import base64

s3 = boto3.client('s3')
BUCKET_NAME = os.environ['S3_BUCKET_NAME']

def handler(event, context):
    try:
        # The file content is in the event body, base64 encoded
        file_content = base64.b64decode(event['body'])
        file_name = event['queryStringParameters'].get('filename', 'default-file.txt')

        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=file_name,
            Body=file_content
        )

        return {
            'statusCode': 200,
            'body': f'File {file_name} uploaded successfully!'
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': 'Error uploading file.'
        }
