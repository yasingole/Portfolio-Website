# Origin Access Control resource
resource "aws_cloudfront_origin_access_control" "web_bucket_access_policy" {
  name                              = "allow_to_s3_from_cloud_front"
  description                       = "Allows access to an S3 web bucket from CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Default cache policy for Cloudfront
resource "aws_cloudfront_cache_policy" "cache_policy" {
  name        = "cache-policy"
  comment     = "-cache-policy"
  default_ttl = 50
  max_ttl     = 100
  min_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "all"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip =  true
  }
}

#  Cloudfront Distribution for S3
resource "aws_cloudfront_distribution" "web_distribution" {
  origin {
    domain_name = aws_s3_bucket.web_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.web_bucket.id
    origin_access_control_id = aws_cloudfront_origin_access_control.web_bucket_access_policy.id
  }

  aliases = [var.domain_name, "www.${var.domain_name}"]

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.domain_name
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.web_bucket.id
    cache_policy_id = aws_cloudfront_cache_policy.cache_policy.id

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
        restriction_type = "none"
        locations = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.certificate.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [ aws_acm_certificate.certificate, aws_route53_record.certificate_validation ]
}

# Useless code