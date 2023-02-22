# Cloud items required for the retriever proof of concept.
# https://github.com/redhatcloudx/cloud-image-retriever

locals {
  s3_origin_id          = "retriever-poc"
  imagedirectory_domain = "poc.imagedirectory.cloud"
}

# Provision an automatically renewing certificate for the CloudFront
# distribution.
resource "aws_acm_certificate" "retriever_poc" {
  domain_name       = local.imagedirectory_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Validate the certificate by creating a DNS record in Route 53.
resource "aws_route53_record" "retriever_poc" {
  for_each = {
    for dvo in aws_acm_certificate.retriever_poc.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.imagedirectory_cloud.zone_id
}

# Set up the CloudFront distribution.
resource "aws_cloudfront_distribution" "retriever_poc" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.cloudx_json_bucket.website_endpoint
    origin_id   = local.s3_origin_id

    # NOTE(mhayden): We need a custom origin config here so that Terraform
    # doesn't explode when it tells CloudFront to use the website URL instead of
    # the normal bucket URL. Using the website URL allows the default root/index
    # functionality to work.
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Retriever proof of concept"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudx_json_bucket.bucket_domain_name
    prefix          = "logs"
  }

  aliases = [local.imagedirectory_domain]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.retriever_poc.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Add a DNS record for the CloudFront distribution.
resource "aws_route53_record" "major_testing" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = local.imagedirectory_domain
  type    = "A"

  lifecycle {
    create_before_destroy = true
  }

  alias {
    name                   = aws_cloudfront_distribution.retriever_poc.domain_name
    zone_id                = aws_cloudfront_distribution.retriever_poc.hosted_zone_id
    evaluate_target_health = false
  }
}
