# Lambda for cache invalidation when changes in s3 occur
# Creating an IAM role for cache invalidation
resource "aws_iam_role" "invalidate_cloud_front_role" {
  name = "invalidate_cloud_front"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

# Creating a policy for the role to invalidate cache
resource "aws_iam_policy" "invalidate_cloud_front_policy" {
  name        = "invalidate_cloud_front_policy"
  description = "Allow to create CloudFront invalidations"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

# Attachment of policy to role
resource "aws_iam_role_policy_attachment" "invalidate_cloud_front_attachment" {
  role       = aws_iam_role.invalidate_cloud_front_role.name
  policy_arn = aws_iam_policy.invalidate_cloud_front_policy.arn
}

# Lambda for cache invalidation when changes in S3 occur
# Script reference
data "archive_file" "invalidate_cloud_front_lambda_zip" {
  type        = "zip"
  source_file = "invalidate_cloud_front.py"  # Adjust the source file path here
  output_path = "invalidate_cloud_front_lambda.zip"
}

# Create the Lambda function
resource "aws_lambda_function" "invalidate_cloud_front_lambda" {
    filename         = data.archive_file.invalidate_cloud_front_lambda_zip.output_path
    function_name    = "invalidate_cloud_front_on_s3_change"
    role             = aws_iam_role.invalidate_cloud_front_role.arn
    handler          = "invalidate_cloud_front.handle_s3_change"
    source_code_hash = data.archive_file.invalidate_cloud_front_lambda_zip.output_base64sha256
    runtime          = "python3.7"
    
    environment {
        variables = {
            CLOUDFRONT_DISTRIBUTION_ID = aws_cloudfront_distribution.web_distribution.id
            }
        }
}

# Lambda permission to allow S3 event notifications
resource "aws_lambda_permission" "allow_s3_event_notifications" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.invalidate_cloud_front_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.web_bucket.arn
}

# Configure S3 bucket notifications to trigger the Lambda function
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.web_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.invalidate_cloud_front_lambda.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}



