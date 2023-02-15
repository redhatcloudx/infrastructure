# Cloud items required for the retriever proof of concept.
# https://github.com/redhatcloudx/cloud-image-retriever

locals {
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