import boto3
import time
import os

def handle_s3_change(event, context):
    """Invalidate the entire CloudFront cache when there are changes in S3."""
    client = boto3.client('cloudfront')
    distribution_id = os.environ['CLOUDFRONT_DISTRIBUTION_ID']
    
    batch = {
        'Paths': {
            'Quantity': 1,
            'Items': ['/*']  # Invalidate the entire distribution
        },
        'CallerReference': str(time.time())
    }
    
    invalidation = client.create_invalidation(
        DistributionId=distribution_id,
        InvalidationBatch=batch,
    )
    
    print("Invalidating the entire CloudFront cache")
    return batch
