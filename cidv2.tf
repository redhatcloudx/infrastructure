# CNAME for custom domain for expirimental fly.io deployment.
# https://fly.io/docs/networking/custom-domain/
resource "aws_route53_record" "experimental_api" {
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