# CNAME for custom domain for expirimental fly.io deployment.
# https://fly.io/docs/networking/custom-domain/
resource "aws_route53_record" "fly_experimental_api" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = "api"
  type    = "CNAME"

  records = [
    "cloudx-cidv2.fly.dev",
  ]

  lifecycle {
    create_before_destroy = true
  }

  ttl = "3600"
}

# Domain validation record for fly.io certificate.
resource "aws_route53_record" "flyio_domain_validation" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = "_acme-challenge.api"
  type    = "CNAME"

  records = [
    "api.imagedirectory.cloud.rgdx8e.flydns.net",
  ]

  lifecycle {
    create_before_destroy = true
  }

  ttl = "3600"
}