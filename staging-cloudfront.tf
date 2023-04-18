# CloudFront confuguration required for the staging environment
locals {
  s3_origin_id_staging          = "cid-staging"
}

# Set up an access identify for CloudFront. We use this in the S3 bucket policy so
# CloudFront can read our private bucket content.
resource "aws_cloudfront_origin_access_identity" "cid_staging" {
  comment = "Access identity for CF to access private S3 bucket ${aws_s3_bucket.cid_bucket_staging.id}"
}

# Provision an automatically renewing certificate for the CloudFront
# distribution.
resource "aws_acm_certificate" "cid_staging" {
  domain_name       = local.imagedirectory_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Look up the AWS SimpleCORS policy.
data "aws_cloudfront_response_headers_policy" "simple_cors_policy_staging" {
  name = "Managed-SimpleCORS"
}

# Set up the CloudFront distribution.
resource "aws_cloudfront_distribution" "cid_staging" {
  origin {
    domain_name = aws_s3_bucket.cid_bucket_staging.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cid_staging.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for CID staging environment."
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cid_bucket_staging.bucket_domain_name
    prefix          = "logs"
  }

  aliases = [local.imagedirectory_domain]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id_staging

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    # Use the SimpleCORS policy from AWS that allows all origins to access the data.
    # TODO(mhayden): We might want to adjust this later to something more limited.
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.simple_cors_policy.id

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
    acm_certificate_arn      = aws_acm_certificate.cid_staging.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code = 404
    response_code = 200
    response_page_path = "/index.html"
  }
}