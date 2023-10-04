# Fetch the AWS account ID dynamically
data "aws_caller_identity" "current" {}

# Creating an IAM role for the Lambda function
resource "aws_iam_role" "increment_visitor_count_role" {
  name = "increment_visitor_count"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })
}

# Creating a policy for the role to access DynamoDB
resource "aws_iam_policy" "increment_visitor_count_policy" {
  name        = "increment_visitor_count_policy"
  description = "Allow Lambda to access DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:UpdateItem"
        ],
        Resource = [
          "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/cloud-resume-stats"
        ]
      }
    ]
  })
}

# Attachment of policy to role
resource "aws_iam_policy_attachment" "increment_visitor_count_attachment" {
  name        = "attach-increment-visitor-count-policy"  # Provide a name for the attachment
  policy_arn  = aws_iam_policy.increment_visitor_count_policy.arn
  roles       = [aws_iam_role.increment_visitor_count_role.name]
}


# Lambda function code to increment visitor count
data "archive_file" "increment_visitor_count_lambda_zip" {
  type        = "zip"
  source_file  = "visitor_count.py"  # Adjust the source file here
  output_path = "visitor_count_lambda.zip"
}

# Create the Lambda function
resource "aws_lambda_function" "increment_visitor_count_lambda" {
  filename         = data.archive_file.increment_visitor_count_lambda_zip.output_path
  function_name    = "IncrementVisitorCount"
  role             = aws_iam_role.increment_visitor_count_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.increment_visitor_count_lambda_zip.output_base64sha256
  runtime          = "nodejs14.x"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = "cloud-resume-stats"
    }
  }
}
