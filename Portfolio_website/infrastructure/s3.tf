# S3 bucket to host website content
resource "aws_s3_bucket" "web_bucket" {
  bucket = "www.${var.domain_name}"
  force_destroy = true
}

# Blocks all public access
resource "aws_s3_bucket_public_access_block" "s3public" {
  bucket = aws_s3_bucket.web_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Static website configuration
resource "aws_s3_bucket_website_configuration" "web_bucket_config" {
  bucket = aws_s3_bucket.web_bucket.id

  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "index.html"
  }
}

# Bucket policy for S3 bucket, only allow from cloudfront distribution
data "aws_iam_policy_document" "web_app_s3_bucket_policy" {
  statement {
    effect = "Allow"
    sid = "CloudFrontAllowRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.web_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = [ "cloudfront.amazonaws.com"]
    }
    condition {
      test = "ArnEquals"
      values = [ aws_cloudfront_distribution.web_distribution.arn ]
      variable = "aws:SourceArn"
    }
  }
}

# Associate bucket policy to S3 bucket
resource "aws_s3_bucket_policy" "web_app_policy" {
  bucket = aws_s3_bucket.web_bucket.id
  policy = data.aws_iam_policy_document.web_app_s3_bucket_policy.json
}

