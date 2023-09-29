# Use data source to find hosted zone
data "aws_route53_zone" "main" {
  name = var.domain_name
}

# Define Route 53 DNS records
locals {
  record_types = toset(["A", "AAAA"])
}

# Record for www. domain
resource "aws_route53_record" "www_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name = "www.${var.domain_name}"
  for_each = local.record_types
  type = each.value

  alias {
    name = aws_cloudfront_distribution.web_distribution.domain_name
    zone_id = aws_cloudfront_distribution.web_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

# Record for Non-www. domain
resource "aws_route53_record" "bare_record" {
  zone_id  = data.aws_route53_zone.main.zone_id
  name     = var.domain_name
  for_each = local.record_types
  type     = each.value

  alias {
    name                   = aws_cloudfront_distribution.web_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.web_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}