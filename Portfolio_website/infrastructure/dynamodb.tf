# Create DynamoDB table
resource "aws_dynamodb_table" "cloud_resume_stats" {
  name         = "cloud-resume-stats"
  billing_mode = "DYNAMIC_PRICING"
  hash_key     = "stats"

  attribute {
    name = "stats"
    type = "S"
  }
}

# Add an item to the DynamoDB table
resource "aws_dynamodb_table_item" "view_count" {
  table_name = aws_dynamodb_table.cloud_resume_stats.name

  hash_key = "stats"
  item = <<EOF
  {
    "stats": {"S": "view-count"},
    "quantity": {"N": "0"}
  }
  EOF
}